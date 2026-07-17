# Ambiente local

## Pré-requisitos

- Docker Desktop com Docker Compose;
- Node.js 24 e npm, para executar o frontend fora de containers;
- .NET SDK 10, para executar a API fora de containers;
- Terraform 1.6 ou superior, somente para validar infraestrutura.

Ferramentas portáteis podem ficar em `.tools/`. Essa pasta é local, está ignorada pelo Git e não deve ser necessária para entender ou clonar o projeto.

## Ambiente integrado com Docker

Na raiz do repositório:

```powershell
docker compose up --build
```

Serviços:

- frontend: `http://localhost:4200`;
- API: `http://localhost:8080`;
- health check: `http://localhost:8080/health`.

O Nginx do container web encaminha `/api/*` e `/health` para a API, reproduzindo o roteamento público. O SQLite fica no volume `foton_sqlite_data`.

Para encerrar sem apagar o banco:

```powershell
docker compose down
```

`docker compose down --volumes` também remove os dados locais; use apenas quando quiser reiniciar o SQLite.

## Execução sem containers

Backend:

```powershell
$env:ASPNETCORE_URLS = "http://localhost:8080"
dotnet run --project src/Foton.Api/Foton.Api.csproj
```

Frontend, em outro terminal:

```powershell
npm ci --prefix apps/web
npm run start --prefix apps/web
```

Por padrão, a API aceita `http://localhost:4200` via CORS e salva o banco em `data/foton.db`, relativo ao diretório do processo.

## Verificações antes de enviar mudanças

```powershell
dotnet build Foton.slnx
npm ci --prefix apps/web
npm run build --prefix apps/web
docker compose config
```

Não é necessário EKS, Kubernetes, EC2 ou Ansible para desenvolver e testar o projeto.
