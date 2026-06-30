# Publicacao na AWS

## Decisao de arquitetura

Para a opcao mais economica do MVP, prefira a trilha EC2 em [infra/ec2-docker](../infra/ec2-docker/README.md). A trilha abaixo com EKS continua disponivel para quando Kubernetes gerenciado fizer sentido.

## Trilha EKS

Este projeto publica os containers pelo Docker Hub e usa AWS apenas para executar a infraestrutura:

- Docker Hub: registry gratuito para `foton-api` e `foton-web`.
- Amazon EKS: Kubernetes gerenciado.
- Amazon RDS PostgreSQL: banco de dados do orcamento.
- Kubernetes Service `LoadBalancer`: entrada publica para o frontend.
- API: servico interno `foton-api` acessado pelo Nginx do frontend em `/api`.

Nao usamos ECR neste desenho.

## Por que Ansible nao entra no caminho principal

Ansible e util quando temos maquinas para configurar. Neste desenho, EKS e RDS sao servicos gerenciados e o Terraform declara a infraestrutura e os workloads Kubernetes. Portanto, nao ha EC2 manual para configurar com Ansible.

Use Ansible depois, se adicionarmos:

- Bastion host.
- Instancias EC2 fora do EKS.
- Rotinas de configuracao em servidores proprios.

Para ambiente local, a melhor opcao e Ansible dentro do WSL2 com Ubuntu. Ansible em container fica melhor para CI ou execucao pontual.

## Pre-requisitos

- Docker Desktop rodando.
- Conta Docker Hub.
- AWS CLI configurado ou credenciais AWS exportadas no ambiente.
- Terraform local em `.tools/terraform`, ja preparado neste workspace.
- Permissoes AWS para criar VPC, EKS, EC2, IAM, Load Balancer e RDS.

## 1. Login no Docker Hub

```powershell
docker login
```

## 2. Publicar imagens no Docker Hub

Substitua `seu-usuario-dockerhub` pelo seu namespace no Docker Hub.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-publish.ps1 `
  -DockerHubNamespace seu-usuario-dockerhub `
  -Tag v1
```

Imagens publicadas:

```text
seu-usuario-dockerhub/foton-api:v1
seu-usuario-dockerhub/foton-web:v1
```

## 3. Configurar credenciais AWS

Opcao com AWS CLI:

```powershell
aws configure
aws sts get-caller-identity
```

Opcao por variaveis:

```powershell
$env:AWS_ACCESS_KEY_ID="..."
$env:AWS_SECRET_ACCESS_KEY="..."
$env:AWS_DEFAULT_REGION="sa-east-1"
```

## 4. Aplicar Terraform

Use uma senha forte para o RDS.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\aws-terraform-apply.ps1 `
  -DockerHubNamespace seu-usuario-dockerhub `
  -ImageTag v1 `
  -DbPassword "troque-por-uma-senha-forte"
```

Ao final, o output `web_load_balancer` deve mostrar o DNS publico do Load Balancer criado pela AWS.

## 5. Consultar o acesso publico

```powershell
cd infra\terraform\aws
..\..\..\.tools\terraform\terraform.exe output web_load_balancer
```

Abra o DNS retornado no navegador.

## 6. Atualizar imagem

Para publicar uma nova versao:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-publish.ps1 `
  -DockerHubNamespace seu-usuario-dockerhub `
  -Tag v2

powershell -ExecutionPolicy Bypass -File .\scripts\aws-terraform-apply.ps1 `
  -DockerHubNamespace seu-usuario-dockerhub `
  -ImageTag v2 `
  -DbPassword "mesma-senha-do-rds"
```

## 7. Destruir ambiente

Isto apaga EKS, RDS e Load Balancer. Use somente quando quiser parar custos.

```powershell
cd infra\terraform\aws
..\..\..\.tools\terraform\terraform.exe destroy `
  -var "dockerhub_namespace=seu-usuario-dockerhub" `
  -var "db_password=troque-por-uma-senha-forte"
```

## Custos

Este desenho cria recursos cobrados: EKS control plane, EC2 nodes, Load Balancer e RDS. Para reduzir custo em POC, mantenha `eks_desired_size=1` e destrua o ambiente quando terminar os testes.
