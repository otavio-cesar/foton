# Higgs Energia - Landing Page EV

Landing page e API para oferta de instalacao de carregadores de veiculos eletricos ate 7 kW em rede bifasica, com opcao de totem/carregador e instalacao de padrao eletrico.

## Stack proposta

- Frontend: Angular standalone
- Backend: .NET 10, Clean Architecture, orientacao a objetos
- Banco: SQLite com snapshot em S3 para MVP
- Containers: Docker
- Orquestracao: ECS Fargate Spot para a API
- Nuvem: AWS
- Infraestrutura: Terraform
- CDN/frontend: S3 privado com CloudFront

## Estrutura

```text
apps/web                 Landing page Angular
src/Foton.Api            API HTTP .NET 10
src/Foton.Application    Casos de uso e contratos
src/Foton.Domain         Entidades e regras de dominio
src/Foton.Infrastructure Banco, assistente virtual e integracoes
deploy/docker            Dockerfiles
deploy/k8s               Manifests Kubernetes
infra/terraform/aws      Provisionamento AWS
infra/aws-static-ecs     S3, CloudFront, ALB e ECS Fargate Spot
infra/ansible            Configuracao de maquinas
docs                     Plano e decisoes tecnicas
```

## Execucao local esperada

Prerequisitos em uma maquina de desenvolvimento:

- Node.js e npm
- .NET SDK 10
- Docker

```powershell
cmd /c npm install --prefix apps\web
cmd /c npm run start --prefix apps\web
powershell -ExecutionPolicy Bypass -File .\scripts\build-backend.ps1
```

## Observacoes do ambiente atual

Este scaffold usa ferramentas locais em `.tools/` para .NET, Terraform e Git neste workspace. Docker e Ansible dependem de instalacao da maquina; veja [docs/ambiente-local.md](docs/ambiente-local.md).

## Publicacao AWS

O caminho atual de publicacao usa Docker Hub para a imagem da API, ECS Fargate Spot para executar o container, S3 privado para o build Angular e CloudFront para entregar o site.

Fluxo basico:

```powershell
.\scripts\docker-publish-api.ps1 -DockerHubNamespace otavioc31 -Tag v2
.\scripts\aws-static-ecs-terraform-apply.ps1 -DockerHubNamespace otavioc31 -ImageTag v2
.\scripts\aws-static-ecs-deploy-frontend.ps1
```

Enquanto o banco for SQLite em arquivo, mantenha apenas uma task da API (`api_desired_count = 1`). Para multiplas instancias ou dados criticos, a proxima evolucao deve ser RDS PostgreSQL ou DynamoDB.
