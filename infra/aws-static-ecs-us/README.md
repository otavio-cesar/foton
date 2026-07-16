# Foton — runtime `us-east-1`

Esta stack administra o runtime regional de produção:

- buckets S3 do frontend e do snapshot SQLite;
- VPC com duas sub-redes públicas;
- ALB;
- ECS Fargate Spot para a API;
- logs do CloudWatch.

CloudFront, Route 53 e ACM ficam na stack global
`infra/aws-static-ecs`. O state deste runtime usa a chave:

```text
foton-ev/prod/us-runtime/terraform.tfstate
```

Enquanto o banco for um arquivo SQLite, mantenha uma única task da API.

## Agendamento atual

O alvo e as ações de Application Auto Scaling foram criados diretamente na
AWS porque a credencial de implantação não possui as permissões de leitura de
tags exigidas pelo provider. Por isso, `schedule_enabled` permanece `false` no
`prod.tfvars`.

- início: 08:00 em `America/Sao_Paulo`;
- parada: 00:00 em `America/Sao_Paulo`;
- capacidade: mínimo 0 e máximo 1.

## Aplicação

Use sempre um arquivo de produção explícito e um plano salvo:

```powershell
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -var-file=prod.tfvars -out=us-runtime.tfplan
terraform apply us-runtime.tfplan
```
