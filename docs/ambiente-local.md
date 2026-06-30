# Ambiente local

## Ferramentas resolvidas neste workspace

As ferramentas abaixo foram instaladas localmente em `.tools/`, sem alterar a instalacao global do Windows:

- .NET SDK 10.0.301
- Terraform 1.15.7
- PortableGit 2.55.0

Como `.tools/` esta no `.gitignore`, essas ferramentas nao devem ser versionadas.

## Comandos validados

Frontend:

```powershell
cmd /c npm run build --prefix apps\web
cmd /c npm run start --prefix apps\web
```

Backend:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-backend.ps1
```

Terraform:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\terraform-validate.ps1
```

Git local:

```powershell
.\.tools\git\cmd\git.exe --version
```

## Pendencias que dependem da maquina

Docker Desktop foi instalado em modo usuario em:

```text
C:\Users\otavio\AppData\Local\Programs\DockerDesktop
```

A CLI esta em:

```text
C:\Users\otavio\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe
```

O usuario `otavio` foi adicionado ao grupo local `docker-users`. Como o grupo foi adicionado depois da sessao atual iniciar, faca logoff/login ou reinicie o Windows antes de validar o daemon.

Depois do reboot:

```powershell
docker version
docker info
docker compose version
docker compose up --build
```

Ansible como control node nao e suportado nativamente no Windows. Para este projeto, a opcao recomendada e WSL2 com Ubuntu e Ansible instalado dentro do Linux. Ansible em container fica como alternativa para CI ou execucoes pontuais depois que Docker estiver funcionando.

Depois que o WSL2 estiver ativo:

```powershell
wsl --install -d Ubuntu
```

Dentro do Ubuntu:

```bash
sudo apt update
sudo apt install -y ansible python3-pip openssh-client
ansible --version
```
