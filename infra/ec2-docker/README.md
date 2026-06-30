# Deploy EC2 Docker

Infraestrutura alternativa e mais economica para publicar a landing page em uma unica EC2 `t3.small` com Docker Compose.

Este diretorio nao substitui a opcao EKS em `infra/terraform/aws`; ele e uma trilha separada para MVP.

## Arquitetura

- EC2 `t3.small` com Amazon Linux 2023.
- Elastic IP.
- Security Group com portas `80`, `443` e `22`.
- Docker e Docker Compose instalados via Ansible.
- Imagens publicadas no Docker Hub.
- Containers:
  - `web`: Angular servido por Nginx.
  - `api`: .NET 10.
  - `database`: PostgreSQL com volume Docker.

## Fluxo

1. Publicar imagens no Docker Hub.
2. Criar a EC2 com Terraform.
3. Rodar Ansible para instalar Docker e subir o compose.
4. Acessar o Elastic IP no navegador.

## 1. Publicar imagens no Docker Hub

```powershell
docker login

powershell -ExecutionPolicy Bypass -File .\scripts\docker-publish.ps1 `
  -DockerHubNamespace seu-usuario-dockerhub `
  -Tag v1
```

## 2. Criar a EC2

Descubra seu IP publico e use `/32` no SSH.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ec2-terraform-apply.ps1 `
  -SshAllowedCidr "SEU_IP_PUBLICO/32"
```

Consultar o IP criado:

```powershell
cd infra\ec2-docker\terraform
..\..\..\.tools\terraform\terraform.exe output public_ip
..\..\..\.tools\terraform\terraform.exe output -raw private_key_path
```

## 3. Preparar arquivo `.env`

Copie `infra/ec2-docker/compose/.env.example` para `infra/ec2-docker/compose/.env` e ajuste:

```text
DOCKERHUB_NAMESPACE=seu-usuario-dockerhub
IMAGE_TAG=v1
POSTGRES_PASSWORD=uma-senha-forte
PUBLIC_ORIGIN=http://SEU_ELASTIC_IP
```

## 4. Criar inventario Ansible

Copie `infra/ec2-docker/ansible/inventory.example.ini` para `inventory.ini` e ajuste o IP e a chave.

```ini
[foton_ec2]
SEU_ELASTIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=../terraform/generated/foton-ev-prod-docker.pem
```

## 5. Rodar Ansible pelo WSL2

No Ubuntu/WSL2:

```bash
cd /mnt/c/Users/otavio/.codex/memories/landing-page/infra/ec2-docker/ansible
ansible-playbook -i inventory.ini playbook.yml
```

## 6. Acessar

Abra:

```text
http://SEU_ELASTIC_IP
```

## Destruir

```powershell
cd infra\ec2-docker\terraform
..\..\..\.tools\terraform\terraform.exe destroy -var "ssh_allowed_cidr=SEU_IP_PUBLICO/32"
```

## Custos

Esta opcao tende a custar menos que EKS porque evita control plane, node group gerenciado, Load Balancer e RDS separados.

Para parar custo de compute, pare ou destrua a EC2. Elastic IP parado/desanexado pode gerar custo.
