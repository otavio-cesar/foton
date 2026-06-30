# Foton Energia Fotovoltaica - Landing Page EV

Landing page e API para oferta de instalacao de carregadores de veiculos eletricos ate 7 kW em rede bifasica, com opcao de totem/carregador e instalacao de padrao eletrico.

## Stack proposta

- Frontend: Angular standalone
- Backend: .NET 10, Clean Architecture, orientacao a objetos
- Banco: Amazon RDS PostgreSQL
- Containers: Docker
- Orquestracao: Kubernetes
- Nuvem: AWS
- Infraestrutura: Terraform
- Configuracao de maquinas: Ansible

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

O plano de publicacao usa Docker Hub para as imagens e Terraform para criar AWS/EKS/RDS. Veja [docs/publicacao-aws.md](docs/publicacao-aws.md).
