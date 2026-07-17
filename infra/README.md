# Infraestrutura

Este diretório contém somente as stacks relacionadas à produção atual. A migração regional para `us-east-1` já foi concluída; o próximo passo planejado é modularizar o Terraform e, depois, habilitar Lambda em paralelo ao ECS.

## Inventário ativo

| Diretório | Responsabilidade | State |
| --- | --- | --- |
| `aws-static-ecs` | CloudFront, OAC do frontend, Route 53 e ACM | `foton-ev/prod/global-edge/terraform.tfstate` |
| `aws-static-ecs-us` | S3 do frontend, S3 do SQLite, rede, ALB, ECS e logs em `us-east-1` | `foton-ev/prod/us-runtime/terraform.tfstate` |
| `terraform-backend` | bucket versionado que armazena os states remotos | state local do bootstrap |

Os nomes `aws-static-ecs` e `aws-static-ecs-us` são históricos e permanecem para não quebrar os procedimentos em uso. A primeira pasta hoje é apenas a camada global. A neutralização de nomes e região deve ocorrer junto da modularização, com `moved` blocks e planos que não recriem recursos.

## O que não faz parte da arquitetura

Não há trilha mantida para:

- Kubernetes ou EKS;
- EC2 administrada diretamente;
- RDS PostgreSQL;
- Ansible;
- runtime paralelo em `sa-east-1`.

O ambiente local é atendido por `docker-compose.yml` e pelos Dockerfiles em `deploy/docker`.

## Regra de segurança

Cada pasta Terraform é uma unidade de operação independente. Sempre confirme o backend e o state antes de gerar um plano:

```powershell
terraform init -backend-config=backend.hcl
terraform state list
terraform validate
terraform plan -var-file=prod.tfvars -out=review.tfplan
terraform show review.tfplan
terraform apply review.tfplan
```

Não aplique um plano com remoção ou substituição inesperada de CloudFront, Route 53, ACM, buckets, ALB, ECS ou rede. Não execute `destroy` no bootstrap enquanto qualquer stack usar seu bucket.

## Evolução

O desenho regional neutro, a extração dos módulos e a infraestrutura necessária para ativar Lambda estão em [Plano de migração para Lambda e modularização do Terraform](../docs/plano-migracao-lambda.md).
