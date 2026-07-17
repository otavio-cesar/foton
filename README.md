# Higgs Energia — landing page EV

Landing page e API de orçamento para instalação de carregadores de veículos elétricos.

## Arquitetura atual

Produção usa:

- Angular 20 em bucket S3 privado, entregue pelo CloudFront;
- API .NET 10 em ECS Fargate Spot atrás de um Application Load Balancer;
- SQLite local à task, com snapshot versionado em S3;
- Route 53 e certificado ACM para `higgsenergia.com.br`;
- Terraform com states separados para a camada global e o runtime regional.

O runtime ativo está em `us-east-1`. A separação de states permite evoluir a região e o backend sem misturar o ciclo de vida do domínio e do CloudFront. Enquanto houver SQLite, a API deve executar com no máximo uma task.

Kubernetes, EKS, EC2, RDS e Ansible não fazem parte da arquitetura atual nem do caminho planejado e, por isso, não são mantidos neste repositório.

## Estrutura

```text
apps/web                     frontend Angular
src/Foton.Api                API HTTP .NET 10
src/Foton.Application        casos de uso e contratos
src/Foton.Domain             entidades e regras de domínio
src/Foton.Infrastructure     persistência e integrações
deploy/docker                imagens da API e do frontend
docker-compose.yml           ambiente local integrado
infra/aws-static-ecs         camada global ativa em produção
infra/aws-static-ecs-us      runtime regional ativo em produção
infra/terraform-backend      bootstrap do state remoto
docs/ambiente-local.md       execução e validação local
docs/plano-migracao-lambda.md plano futuro de Lambda e modularização
```

Os nomes das duas pastas de produção são históricos. Não os use como modelo para novas regiões; a estrutura regional neutra está definida no [plano de migração para Lambda](docs/plano-migracao-lambda.md).

## Execução local

O caminho mais próximo do ambiente publicado usa Docker Compose:

```powershell
docker compose up --build
```

- site: `http://localhost:4200`
- API: `http://localhost:8080`
- health check: `http://localhost:8080/health`

O volume `foton_sqlite_data` preserva o banco entre reinicializações. Veja também [Ambiente local](docs/ambiente-local.md) para executar frontend e backend sem containers.

## Validação

```powershell
dotnet build Foton.slnx
npm ci --prefix apps/web
npm run build --prefix apps/web
docker compose config
```

## Infraestrutura de produção

O inventário das stacks e seus limites de responsabilidade está em [infra/README.md](infra/README.md). Antes de qualquer alteração:

1. inicialize a pasta com o `backend.hcl` correto;
2. use sempre o arquivo de variáveis explícito do ambiente;
3. salve o plano e revise todos os `create`, `update` e `destroy`;
4. aplique exatamente o plano revisado;
5. rejeite qualquer substituição inesperada de CloudFront, Route 53, ACM, buckets ou runtime.

Remover arquivos Terraform do Git não remove recursos da AWS por si só, mas uma aplicação posterior pode fazê-lo. As stacks ativas foram preservadas integralmente.

## Próxima evolução

A única migração planejada é de ECS/ALB/SQLite para Lambda .NET 10 com um objeto JSON por orçamento no S3. A Lambda será criada em paralelo, habilitada por configuração e validada antes da troca do CloudFront. A modularização do Terraform deve primeiro representar a infraestrutura atual sem recriar recursos e sem fixar `sa-east-1` ou `us-east-1` no código dos módulos.

Detalhes, fases, rollback e critérios de aceite: [Plano de migração para Lambda e modularização do Terraform](docs/plano-migracao-lambda.md).
