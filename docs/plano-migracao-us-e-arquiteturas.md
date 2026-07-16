# Plano de migração para os Estados Unidos e evolução das arquiteturas

Data de referência: 16/07/2026.

## Resultado da execução em 16/07/2026

A migração regional foi concluída. O usuário autorizou manutenção imediata,
descarte do banco anterior e remoção sem período de retenção; essas decisões
substituem as janelas conservadoras das fases 3 a 5 deste plano.

- CloudFront, Route 53, domínio e certificado foram preservados.
- Frontend, ALB, ECS Fargate Spot, rede, logs e buckets foram recriados em
  `us-east-1`.
- O banco SQLite de destino foi reiniciado vazio.
- O CloudFront usa somente as origens de `us-east-1`.
- ALB, ECS, VPC, logs, buckets, agendamentos e task definitions do projeto em
  `sa-east-1` foram removidos.
- O backend do Terraform também foi migrado para `us-east-1`; o bucket e a
  tabela de lock antigos foram excluídos.
- Os states ficaram separados em `global-edge` e `us-runtime`, preparando a
  modularização posterior sem implementar Lambda nesta etapa.

O restante deste documento preserva o plano original e a arquitetura futura
`lambda_s3` como referência histórica.

## Decisões registradas

O trabalho será dividido em dois momentos:

1. Migrar a arquitetura atual de `sa-east-1` para `us-east-1`, preservando CloudFront, S3, ALB, ECS Fargate Spot, SQLite com snapshot no S3 e o horário de operação da API.
2. Depois da estabilização nos Estados Unidos, modularizar o Terraform para permitir a convivência e a troca controlada entre:
   - backend `ecs_alb`: ALB + ECS + SQLite/S3;
   - backend `lambda_s3`: Lambda .NET + um objeto JSON no S3 por orçamento.

Neste primeiro momento, a arquitetura da aplicação não será trocada por Lambda. O plano da Lambda fica preservado neste documento para execução posterior.

## Motivação e expectativa de custo

O preço fixo atual do ALB em São Paulo é de US$ 0,034 por hora, aproximadamente US$ 24,82 por mês considerando 730 horas, além das LCUs. Em `us-east-1`, o valor fixo é US$ 0,0225 por hora, aproximadamente US$ 16,43 por mês. A redução esperada somente no valor fixo do ALB é de aproximadamente US$ 8,40 por mês, ou 34%.

As LCUs também passam de US$ 0,011 para US$ 0,008 por LCU-hora. ECS/Fargate, armazenamento e outros recursos regionais também tendem a ser mais baratos nos Estados Unidos, mas seus valores devem ser confirmados na fatura após a migração.

Fontes de preço:

- [AWS Price List — ALB em São Paulo](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSELB/20260619024706/sa-east-1/index.json)
- [AWS Price List — ALB em Virgínia](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSELB/20260619024706/us-east-1/index.json)

O domínio `.com.br` continuará apontando para o CloudFront. CloudFront e Route 53 são globais, e o certificado do CloudFront já precisa estar em `us-east-1`. A região da hospedagem não é determinada pela extensão do domínio.

## Arquitetura durante a primeira migração

Fluxo atual em São Paulo:

```text
Registro.br / Route 53
          |
      CloudFront
       |      |
       |      +--> ALB sa-east-1 --> ECS Fargate Spot
       |                              |
       +--> S3 frontend               +--> SQLite --> snapshot S3
```

Fluxo pretendido nos Estados Unidos:

```text
Registro.br / Route 53
          |
      CloudFront
       |      |
       |      +--> ALB us-east-1 --> ECS Fargate Spot
       |                             |
       +--> S3 frontend              +--> SQLite --> snapshot S3
```

Permanecem globais ou inalterados:

- domínio `higgsenergia.com.br`;
- zona e registros do Route 53;
- distribuição CloudFront e suas URLs;
- certificado ACM do CloudFront em `us-east-1`;
- imagem imutável da API no Docker Hub;
- contrato público `POST /api/quotes` e `GET /health`.

São recriados em `us-east-1`:

- VPC, sub-redes públicas, Internet Gateway e tabelas de rota;
- grupos de segurança;
- ALB, listener e target group;
- cluster, task definition e serviço ECS;
- agendamentos de início às 08:00 e parada às 00:00 em `America/Sao_Paulo`;
- log group do CloudWatch;
- bucket do frontend;
- bucket do snapshot SQLite.

O backend remoto do Terraform pode permanecer inicialmente em `sa-east-1`. A localização do state não determina a região dos recursos gerenciados, seu custo é muito pequeno e movê-lo junto aumentaria o risco sem benefício relevante. Uma eventual migração do state deve ser tratada separadamente.

## Estratégia de migração

### Fase 0 — inventário e linha de base

1. Registrar todos os recursos atuais, IDs, ARNs, tags e outputs.
2. Registrar a revisão ativa da task definition e o digest/tag da imagem.
3. Baixar uma cópia de segurança do snapshot SQLite e confirmar que ela abre e contém a quantidade esperada de orçamentos.
4. Registrar os custos atuais por tipo de uso, principalmente:
   - `SAE1-LoadBalancerUsage`;
   - `SAE1-LCUUsage`;
   - Fargate vCPU e memória;
   - IPv4 público;
   - S3 e CloudFront.
5. Registrar o comportamento atual de `/health` e `POST /api/quotes`.

### Fase 1 — criar a infraestrutura paralela em `us-east-1`

1. Criar um state regional separado para o destino, sem alterar o state da pilha em São Paulo.
2. Reproduzir em `us-east-1` a VPC, as duas sub-redes, os grupos de segurança, ALB, ECS, logs e buckets.
3. Fixar a mesma imagem imutável atualmente validada em produção.
4. Criar inicialmente o serviço ECS de destino com capacidade zero, evitando que ele carregue ou grave o banco antes da hora.
5. Configurar o agendamento no fuso `America/Sao_Paulo`, mas impedir que ele seja ativado antes do corte.
6. Não alterar ainda a distribuição CloudFront, Route 53 ou ACM.

### Fase 2 — preparar frontend e dados

1. Publicar o mesmo build Angular no novo bucket do frontend.
2. Validar arquivos, headers, `index.html` e permissões do bucket.
3. Copiar uma versão de teste do snapshot SQLite para o bucket de destino.
4. Iniciar temporariamente uma tarefa ECS no destino, sem tráfego público do domínio.
5. Validar:
   - inicialização da API;
   - download do SQLite;
   - `/health`;
   - acesso ao S3;
   - criação de snapshot consistente;
   - logs e permissões IAM.
6. Encerrar novamente a tarefa de teste. Qualquer orçamento criado nessa etapa deve ser explicitamente marcado como teste.

### Fase 3 — corte regional entre 00:00 e 08:00

O corte deve aproveitar a janela em que a API já fica indisponível por decisão operacional. Isso evita duas instâncias regionais escrevendo versões diferentes do mesmo SQLite.

1. Confirmar que a tarefa em São Paulo chegou a zero após 00:00.
2. Desabilitar o próximo início automático do serviço em São Paulo.
3. Confirmar que não há tarefa antiga ativa nem upload de snapshot em andamento.
4. Copiar o snapshot SQLite final de São Paulo para o bucket em `us-east-1`.
5. Comparar tamanho, hash e quantidade de registros entre origem e destino.
6. Iniciar o ECS de destino e confirmar `/health` diretamente no novo ALB.
7. Alterar as origens da distribuição CloudFront:
   - origem padrão para o novo bucket do frontend;
   - `/api/*` e `/health` para o novo ALB.
8. Aguardar a implantação completa da configuração do CloudFront.
9. Testar pelo domínio público sem criar inicialmente dados reais.
10. Executar um orçamento controlado e confirmar:
    - resposta HTTP `201`;
    - registro no SQLite;
    - snapshot atualizado no S3 de `us-east-1`.
11. Deixar habilitado apenas o agendamento do ECS em `us-east-1`.

### Fase 4 — observação e retorno

1. Manter a infraestrutura de São Paulo intacta por pelo menos 72 horas, porém com ECS em capacidade zero.
2. Monitorar:
   - `5xx` do CloudFront e ALB;
   - falhas de health check;
   - reinícios da tarefa;
   - uploads do snapshot;
   - divergência ou perda de registros;
   - horário de início e parada.
3. Se a falha ocorrer antes de novos orçamentos reais, voltar as origens do CloudFront para São Paulo e reativar seu agendamento.
4. Se já houver dados novos nos Estados Unidos, antes do retorno:
   - parar o ECS dos Estados Unidos;
   - copiar o snapshot mais recente de volta para São Paulo;
   - validar hash e registros;
   - somente então retornar o CloudFront e reativar o ECS antigo.
5. Nunca manter simultaneamente os dois serviços aceitando gravações.

### Fase 5 — desativar São Paulo

Após a janela de observação:

1. Fazer uma cópia final do snapshot antigo.
2. Remover ALB, listener, target group, ECS, agendamentos, VPC e logs antigos.
3. Preservar os buckets antigos por 30 dias com acesso bloqueado e sem novas gravações.
4. Depois dos 30 dias, decidir entre retenção arquivada ou exclusão.
5. Confirmar na fatura que `SAE1-LoadBalancerUsage` e `SAE1-LCUUsage` pararam de crescer.
6. Confirmar o início das cobranças equivalentes `USE1` e comparar o mês normalizado.

## Guardas obrigatórias para Terraform

O fluxo anterior já mostrou que variáveis omitidas podem produzir um plano que remove domínio e DNS. Para evitar repetição:

1. Manter valores não secretos de produção em um arquivo de configuração versionado por ambiente.
2. Manter segredos fora do repositório, usando variáveis de ambiente, SSM ou Secrets Manager.
3. O comando de `plan` deve sempre receber explicitamente a configuração do ambiente.
4. Salvar o plano em arquivo e aplicar exatamente o plano revisado.
5. Bloquear a execução se o plano contiver remoção ou recriação inesperada de:
   - distribuição CloudFront;
   - zona e registros Route 53;
   - certificado ACM;
   - bucket de state;
   - bucket SQLite antes da cópia de segurança.
6. Usar state separado para origem, destino e componentes globais durante a migração.
7. Nunca resolver a migração apenas mudando `aws_region` no state monolítico atual. Isso misturaria recursos globais e regionais e poderia causar substituições destrutivas.

Fluxo pretendido:

```text
terraform init  -> backend correto do ambiente
terraform validate
terraform plan  -> var-file obrigatório + plano salvo
revisão humana  -> lista exata de create/update/destroy
terraform apply -> somente o plano salvo
```

## Modularização posterior

A modularização deve separar ciclo de vida global, regional e de backend:

```text
infra/
  modules/
    edge/                 # CloudFront, comportamentos e integração com as origens
    dns-certificate/      # Route 53 e ACM
    static-site/          # bucket e publicação do frontend
    network/              # VPC, sub-redes e segurança
    backend-ecs-alb/      # ALB, ECS, logs, agenda e snapshot SQLite
    backend-lambda-s3/    # Lambda, Function URL/OAC e JSONs no S3
  environments/
    prod/
      global-edge/
      sa-runtime/
      us-runtime/
```

As configurações devem separar os backends provisionados do backend que recebe tráfego:

```hcl
runtime_region  = "us-east-1"
enabled_backends = ["ecs_alb"]
active_backend   = "ecs_alb"

ecs_schedule_enabled = true
ecs_start_hour       = 8
ecs_stop_hour        = 0
ecs_schedule_timezone = "America/Sao_Paulo"
```

Durante uma futura migração para Lambda:

```hcl
enabled_backends = ["ecs_alb", "lambda_s3"]
active_backend   = "ecs_alb"
```

Depois da validação:

```hcl
enabled_backends = ["ecs_alb", "lambda_s3"]
active_backend   = "lambda_s3"
```

Somente depois da janela de retorno:

```hcl
enabled_backends = ["lambda_s3"]
active_backend   = "lambda_s3"
```

Esse desenho evita que a simples troca de uma variável destrua imediatamente a arquitetura anterior. O módulo `edge` deve receber outputs padronizados de origem, sem conhecer a implementação interna do backend.

Ao extrair recursos existentes para módulos, devem ser usados blocos `moved` e planos sem recriação para preservar os recursos e o state.

## Plano futuro preservado: Lambda + S3

Quando houver decisão para retirar ALB e ECS:

1. Criar uma Lambda pequena em .NET 10, publicada como ZIP e fora de VPC.
2. Preservar `POST /api/quotes`, resposta `201` e `GET /health`.
3. Usar Lambda Function URL com `AWS_IAM` e CloudFront Origin Access Control.
4. Salvar cada orçamento como um JSON independente em bucket privado:

```text
quotes/AAAA/MM/DD/data-hora-uuid.json
```

5. Não usar um arquivo SQLite compartilhado entre execuções Lambda.
6. Usar chave de idempotência para impedir registros duplicados em tentativas repetidas.
7. Configurar timeout da Lambda entre 10 e 15 segundos e manter inicialmente o timeout do CloudFront em 30 segundos.
8. Medir cold start em `us-east-1`, buscando:
   - resposta aquecida inferior a 1 segundo;
   - cold start normalmente inferior a 3 segundos;
   - nenhuma resposta acima do timeout.
9. Criar Lambda e S3 em paralelo ao ECS, mudar somente o backend ativo e preservar o ECS para retorno.
10. Após validação, remover ALB, ECS, VPC, agenda e SQLite.

O DynamoDB não é necessário para o requisito atual. Ele deve ser reconsiderado somente se surgirem consultas frequentes, filtros, atualizações de status, painel administrativo ou maior concorrência.

Referências:

- [CloudFront protegido para Lambda Function URL](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-lambda.html)
- [Runtime gerenciado .NET 10 no Lambda](https://aws.amazon.com/about-aws/whats-new/2026/01/aws-lambda-dot-net-10/)
- [Preços do S3](https://aws.amazon.com/s3/pricing/)

## Critérios de conclusão da migração regional

A migração para `us-east-1` será considerada concluída quando:

- domínio e frontend continuarem acessíveis sem mudança de URL;
- API responder somente pelo backend dos Estados Unidos;
- orçamento novo aparecer no snapshot correto;
- agendamento funcionar às 08:00 e 00:00 no horário de São Paulo;
- nenhum serviço em São Paulo continuar aceitando gravações;
- houver procedimento de retorno validado;
- recursos cobrados de São Paulo forem removidos após a retenção;
- a fatura mostrar a redução esperada.

## Riscos e decisões conscientes

- Dados de nome, telefone, e-mail e cidade serão armazenados nos Estados Unidos. Isso caracteriza transferência internacional de dados pessoais e deve ser refletido na análise de LGPD, nos contratos aplicáveis e no aviso de privacidade.
- O SQLite exige apenas uma tarefa gravando. A migração não pode operar em modo ativo-ativo.
- O ALB continuará com custo fixo nos Estados Unidos; esta migração reduz, mas não elimina, esse custo.
- A eliminação do custo fixo do ALB será tratada posteriormente pelo backend `lambda_s3`.
- O state do Terraform e os dados da aplicação têm ciclos de vida diferentes e não devem ser migrados na mesma operação.
