# Plano de migração para Lambda e modularização do Terraform

Data de referência: 16/07/2026.

## Resumo

A migração de `sa-east-1` para `us-east-1` já terminou e não faz parte deste plano. A única evolução planejada é:

1. modularizar o Terraform sem recriar a infraestrutura atual;
2. tornar o runtime reutilizável em qualquer região AWS;
3. adicionar a infraestrutura de Lambda como backend opcional e inicialmente desligado;
4. criar e validar Lambda + S3 em paralelo ao ECS;
5. trocar o backend ativo no CloudFront;
6. remover ALB, ECS, rede e SQLite somente após a janela de retorno.

EKS, Kubernetes, EC2 administrada diretamente, RDS e Ansible estão fora do escopo.

## Linha de base confirmada

Em 16/07/2026:

- o domínio e o frontend respondiam com HTTP 200 pelo CloudFront;
- `GET /health` respondia HTTP 200;
- o state `global-edge` continha CloudFront, OAC, Route 53 e ACM;
- o state `us-runtime` continha S3, VPC, ALB, ECS, IAM e logs;
- o serviço ECS em `us-east-1` estava ativo com uma task;
- o cluster e o serviço antigos de `sa-east-1` estavam `INACTIVE`, sem tasks;
- não havia instâncias EC2 do projeto em `sa-east-1` ou `us-east-1`.

As pastas ativas continuam sendo:

```text
infra/aws-static-ecs       camada global
infra/aws-static-ecs-us    runtime de produção em us-east-1
infra/terraform-backend    bucket dos states
```

Os nomes são históricos. Renomeá-los não é pré-requisito da modularização e não deve ser misturado com a primeira refatoração.

## Invariantes

A evolução deve preservar:

- `https://higgsenergia.com.br` e `https://www.higgsenergia.com.br`;
- o contrato público `POST /api/quotes`;
- resposta `201` para um orçamento criado;
- `GET /health`;
- frontend privado atrás do CloudFront;
- dados privados e criptografados no S3;
- possibilidade de voltar ao ECS sem recuperar infraestrutura;
- uma única região ativa para gravação;
- states separados por ciclo de vida;
- aplicação de planos salvos e revisados.

Nenhuma fase pode:

- trocar a região por simples alteração no state monolítico;
- destruir e recriar CloudFront, Route 53 ou ACM;
- mover recursos entre states sem backup e lista explícita;
- remover ECS no mesmo passo que ativa Lambda;
- compartilhar o arquivo SQLite entre execuções Lambda;
- manter ECS e Lambda recebendo gravações reais ao mesmo tempo.

## Arquitetura-alvo

```text
Route 53
   |
CloudFront
   |------------------------> S3 privado do frontend
   |
   +-- active_backend=ecs --> ALB --> ECS --> SQLite --> snapshot S3
   |
   +-- active_backend=lambda --> Function URL + OAC --> Lambda --> JSONs no S3
```

Durante a migração, os dois backends podem estar provisionados, mas somente um recebe tráfego público:

```hcl
runtime_region  = "us-east-1"
enabled_backends = ["ecs", "lambda"]
active_backend   = "ecs"
```

Depois da validação:

```hcl
runtime_region  = "us-east-1"
enabled_backends = ["ecs", "lambda"]
active_backend   = "lambda"
```

Somente após a janela de retorno:

```hcl
runtime_region  = "us-east-1"
enabled_backends = ["lambda"]
active_backend   = "lambda"
```

Uma validação Terraform deve exigir que `active_backend` pertença a `enabled_backends`.

## Proposta de módulos

A árvore final deve separar abstrações e ciclos de vida, sem criar wrappers para recursos isolados:

```text
infra/
  modules/
    edge/
    static-site/
    network/
    backend-ecs/
    backend-lambda/
  environments/
    prod/
      global-edge/
      runtime/
  terraform-backend/
```

Responsabilidades:

| Módulo | Recursos |
| --- | --- |
| `edge` | CloudFront, OACs, comportamentos e seleção do backend |
| `static-site` | bucket, criptografia, versionamento, acesso privado e policy do frontend |
| `network` | VPC, sub-redes, rotas e grupos de segurança usados somente pelo ECS |
| `backend-ecs` | ALB, ECS, IAM, logs, agenda e snapshot SQLite |
| `backend-lambda` | bucket de orçamentos, Lambda, Function URL, IAM, logs e alarmes |

`edge` não deve conhecer detalhes internos de ECS ou Lambda. Os módulos de backend devem expor um contrato de origem padronizado:

```hcl
api_origin = {
  kind        = "alb" # ou "lambda"
  domain_name = "..."
  oac_id      = null  # preenchido para Lambda
}
```

A raiz escolhe a origem com `active_backend` e entrega somente o resultado ao módulo `edge`.

## Independência de região

Os módulos não devem conter `us`, `sa`, `us-east-1` ou `sa-east-1` nos nomes lógicos. A região entra pelo provider da raiz:

```hcl
variable "runtime_region" {
  type = string
}

provider "aws" {
  region = var.runtime_region
}
```

Exceção: o certificado usado pelo CloudFront permanece em `us-east-1`, conforme exigência do serviço, por meio de provider com alias na raiz global.

Para não substituir recursos atuais, o prefixo físico deve ser uma entrada independente da região:

```hcl
resource_name_prefix = "foton-ev-prod-us"
```

Novos ambientes podem derivar seu próprio prefixo, mas a infraestrutura já existente conserva os nomes físicos atuais.

O backend remoto não aceita interpolação de variáveis. Cada ambiente/região deve ter um `backend.hcl` local explícito, com uma chave como:

```text
foton-ev/prod/runtime/us-east-1/terraform.tfstate
```

A mudança da chave atual `us-runtime` é opcional e deve ocorrer apenas em uma etapa dedicada. A região do bucket de state não precisa acompanhar a região do runtime.

## Como modularizar sem recriar produção

### Etapa 1 — inventário e backup

1. Fazer backup dos states `global-edge` e `us-runtime`.
2. Salvar `terraform state list` das duas raízes.
3. Registrar outputs, IDs, nomes físicos e providers.
4. Confirmar health check e criação de orçamento antes da mudança.
5. Congelar alterações paralelas na infraestrutura.

### Etapa 2 — extrair a camada global

1. Criar os módulos necessários.
2. Manter `infra/aws-static-ecs` como raiz de compatibilidade.
3. Mover a configuração para os módulos.
4. Adicionar um `moved` block para cada endereço alterado.
5. Executar `terraform plan` contra o state real.
6. Aceitar apenas movimentos de endereço, sem `add`, `change` ou `destroy` inesperado.
7. Aplicar o plano e manter os `moved` blocks versionados.

Exemplo:

```hcl
moved {
  from = aws_cloudfront_distribution.frontend
  to   = module.edge.aws_cloudfront_distribution.frontend
}
```

### Etapa 3 — extrair o runtime ECS

Repetir o processo no state `us-runtime`, separando `static-site`, `network` e `backend-ecs`. Recursos que exigem atenção especial:

- bucket e policy do frontend;
- bucket do SQLite e suas versões;
- VPC, sub-redes e tabelas de rota;
- security groups;
- ALB, listener e target group;
- cluster, serviço e task definition ECS;
- roles e policies IAM;
- log group;
- agendamentos que hoje existem parcialmente fora do state.

Os agendamentos devem ser importados ou mantidos explicitamente fora do Terraform antes da extração. Não criar recursos com o mesmo nome por acidente.

### Etapa 4 — criar a raiz regional neutra

Depois de pelo menos uma aplicação estável dos módulos:

1. criar `environments/prod/runtime`;
2. usar o mesmo backend e a mesma chave inicialmente;
3. fornecer `runtime_region = "us-east-1"`;
4. confirmar plano vazio;
5. atualizar procedimentos locais;
6. somente então considerar descontinuar a raiz histórica.

Mover arquivos de pasta não muda recursos. Trocar a chave do backend ou os endereços do state muda.

## Infraestrutura de Lambda preparada e desligada

O módulo `backend-lambda` e sua chamada devem existir antes da migração, mas sem recursos quando Lambda não estiver habilitada:

```hcl
module "backend_lambda" {
  for_each = contains(var.enabled_backends, "lambda") ? toset(["lambda"]) : toset([])

  source = "../../../modules/backend-lambda"

  runtime_region              = var.runtime_region
  resource_name_prefix        = var.resource_name_prefix
  cloudfront_distribution_arn = var.cloudfront_distribution_arn
}
```

Com `enabled_backends = ["ecs"]`, o plano deve continuar sem recursos Lambda. Ao incluir `"lambda"`, o módulo cria:

- bucket S3 privado para um JSON por orçamento;
- bloqueio de acesso público;
- criptografia em repouso;
- versionamento e regra de retenção;
- role de execução da Lambda;
- policy mínima para gravar, ler e listar apenas o prefixo necessário;
- Lambda .NET 10 publicada como ZIP e fora de VPC;
- Function URL com autenticação `AWS_IAM`;
- permissões `lambda:InvokeFunctionUrl` e `lambda:InvokeFunction` limitadas à distribuição;
- log group com retenção definida;
- alarmes de erro, throttling e duração.

O OAC da origem Lambda pertence ao módulo global `edge`. O ARN da distribuição já existente entra no runtime como variável explícita ou output remoto, evitando dependência circular entre os dois states.

Segredos não devem entrar em `tfvars` nem no state. Se forem necessários, usar SSM Parameter Store ou Secrets Manager e conceder acesso mínimo à role.

## Alterações da aplicação

Criar uma entrada de execução Lambda sem duplicar domínio e casos de uso:

```text
src/Foton.Lambda
src/Foton.Infrastructure/Persistence/S3
```

O projeto Lambda reutiliza `Foton.Application` e `Foton.Domain`. A persistência atual continua disponível para ECS, e uma implementação `S3QuoteRepository` é selecionada no composition root da Lambda.

Cada orçamento deve ser um objeto independente:

```text
quotes/AAAA/MM/DD/<idempotency-key-ou-uuid>.json
```

O JSON inclui versão do schema, ID, data UTC, dados recebidos e status. Não deve conter segredos ou dados derivados desnecessários.

### Idempotência

O frontend deve enviar uma chave de idempotência por tentativa lógica. A Lambda:

1. valida a chave;
2. deriva uma chave S3 determinística;
3. usa escrita condicional para não sobrescrever objeto existente;
4. em repetição, lê o objeto existente e devolve a mesma resposta;
5. registra conflito quando o mesmo identificador chegar com conteúdo diferente.

Sem isso, retries do navegador, CloudFront ou Lambda podem gerar orçamentos duplicados.

### Compatibilidade HTTP

Manter:

- `POST /api/quotes`;
- `201 Created`;
- validações e mensagens atuais;
- `GET /health`;
- CORS para os dois domínios públicos.

Para Function URL protegida por OAC, a AWS exige que requisições `PUT` e `POST` enviem `x-amz-content-sha256` com o SHA-256 do corpo. Antes do corte, o frontend deve calcular o hash dos mesmos bytes UTF-8 enviados, encaminhar o header pelo CloudFront e passar pelos testes de CORS. Se essa abordagem não for confiável no navegador, a decisão deve ser reaberta e um API Gateway HTTP API deve ser avaliado; não se deve tornar a Function URL pública para contornar o requisito.

## Migração para Lambda

### Fase 0 — critérios de entrada

- modularização aplicada sem recriação;
- build Lambda reproduzível;
- testes unitários do repositório S3 e da idempotência;
- teste local do contrato HTTP;
- backup recente do SQLite;
- inventário dos orçamentos existentes;
- dashboard e alarmes preparados.

### Fase 1 — provisionar em paralelo

1. Alterar `enabled_backends` para `["ecs", "lambda"]`.
2. Manter `active_backend = "ecs"`.
3. Revisar o plano regional: somente recursos Lambda/S3/IAM/logs devem ser criados.
4. Publicar o pacote imutável da Lambda.
5. Aplicar na camada global a nova origem, seu OAC e um comportamento canário temporário, ainda com `/api/*` apontando para ECS.
6. Testar a Function URL pela cadeia autorizada no caminho canário, sem mudar as rotas públicas existentes.
7. Confirmar que acesso direto não autorizado é rejeitado.

### Fase 2 — validar

Validar:

- `GET /health`;
- preflight CORS;
- `POST /api/quotes` com `x-amz-content-sha256`;
- resposta `201`;
- JSON criado no prefixo esperado;
- retry com a mesma chave sem duplicação;
- logs sem dados pessoais desnecessários;
- alarmes;
- latência aquecida e cold start;
- timeout do CloudFront;
- negação de escrita fora do prefixo IAM.

Orçamentos de teste devem ser identificáveis e removidos conforme a política definida.

### Fase 3 — corte

Realizar em janela de baixo tráfego:

1. confirmar Lambda saudável;
2. confirmar ECS saudável para retorno;
3. alterar somente `active_backend` para `"lambda"`;
4. revisar um plano que mude apenas a origem/comportamento necessário do CloudFront;
5. aplicar e aguardar a distribuição concluir a implantação;
6. validar health e criar um orçamento controlado pelo domínio;
7. confirmar o JSON, resposta e logs;
8. desabilitar o agendamento do ECS e reduzir sua capacidade a zero;
9. confirmar que não há task ECS executando;
10. remover o comportamento canário temporário;
11. manter a infraestrutura ECS provisionada para retorno, mas sem aceitar gravações.

Não migrar o SQLite para um único objeto JSON. Os dados históricos podem permanecer em backup somente leitura ou ser convertidos, em processo separado, para um JSON por orçamento.

### Fase 4 — observação e retorno

Manter ECS, ALB, rede, imagem e snapshot por pelo menos sete dias. Monitorar:

- erros e throttling da Lambda;
- `5xx` do CloudFront;
- duração e cold starts;
- falhas de escrita S3;
- duplicidade;
- volume de orçamentos;
- custo.

Retorno:

1. interromper o diagnóstico que gere novos testes;
2. iniciar uma task ECS e aguardar o ALB ficar saudável;
3. alterar apenas `active_backend` para `"ecs"`;
4. aplicar e aguardar o CloudFront;
5. reabilitar o agendamento anterior;
6. validar health e orçamento pelo domínio;
7. preservar os JSONs já recebidos pela Lambda;
8. reconciliar esses dados com o repositório ativo antes de uma nova tentativa de corte.

Não copiar os JSONs para o SQLite durante o retorno sem uma rotina explícita e testada.

### Fase 5 — desativar ECS

Após a janela de retorno e reconciliação:

1. fazer backup final do SQLite e registrar contagem/hash;
2. remover `"ecs"` de `enabled_backends`;
3. revisar individualmente os recursos a destruir;
4. confirmar que CloudFront aponta para Lambda;
5. destruir ALB, ECS, rede, agenda, logs e bucket de snapshot somente conforme a política de retenção;
6. manter os `moved` blocks da modularização;
7. confirmar na fatura que cobranças do ALB e Fargate cessaram.

O bucket do frontend e a camada global permanecem.

## Guardas de Terraform

Todo fluxo de produção deve seguir:

```text
terraform init       backend explícito
terraform validate
terraform plan       var-file explícito + plano salvo
terraform show       revisão humana
terraform apply      exatamente o plano salvo
```

Bloquear a aplicação quando houver:

- backend ou conta AWS inesperada;
- `destroy` fora da fase aprovada;
- substituição de CloudFront, Route 53, ACM ou buckets;
- mudança de região de recurso existente;
- `active_backend` não habilitado;
- imagem ou pacote mutável;
- remoção simultânea de ECS e ativação de Lambda;
- mudança não revisada de policy IAM;
- plano gerado sem arquivo de ambiente.

`moved` blocks devem ser preferidos a comandos manuais de state e permanecer no código até todos os ambientes terem aplicado a migração.

## Critérios de conclusão

A migração termina quando:

- a infraestrutura atual foi modularizada sem recriação;
- a mesma raiz regional aceita `runtime_region` sem regra específica para Brasil ou Estados Unidos;
- Lambda e ECS podem coexistir por configuração;
- CloudFront seleciona o backend sem conhecer sua implementação;
- o domínio e o contrato HTTP permanecem iguais;
- cada orçamento gera um JSON privado e idempotente;
- acesso direto não autorizado à Function URL falha;
- métricas, logs e alarmes estão ativos;
- rollback para ECS foi ensaiado;
- a janela de observação terminou;
- dados foram reconciliados;
- ALB, ECS, rede e SQLite foram removidos por plano separado.

## Riscos e decisões pendentes

- Nome, telefone, e-mail e cidade são dados pessoais. Região, retenção, acesso e transferência internacional precisam estar alinhados à LGPD e ao aviso de privacidade.
- O requisito de hash do corpo para `POST` via OAC precisa de uma prova técnica no Angular antes da aprovação da arquitetura.
- S3 funciona para gravação por objeto e leitura por chave; caso surjam filtros, atualizações frequentes, painel ou concorrência maior, reavaliar DynamoDB.
- A remoção do ALB elimina custo fixo, mas custos de Lambda, CloudFront, logs e S3 devem ser medidos.
- Cold start deve ser medido com o pacote real. Não definir provisão de concorrência antes de existir necessidade observada.

## Referências

- [CloudFront OAC para Lambda Function URL](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-lambda.html)
- [Autorização de Lambda Function URLs](https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html)
- [Funções Lambda com C# e runtime .NET 10](https://docs.aws.amazon.com/lambda/latest/dg/lambda-csharp.html)
- [Refatoração de módulos com `moved` blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
