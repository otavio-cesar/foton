# Foton — camada global de produção

Apesar do nome histórico da pasta, esta stack não contém ECS nem recursos regionais de aplicação. Ela administra:

- distribuição e Origin Access Control do CloudFront;
- zona e registros do Route 53;
- certificado ACM do CloudFront em `us-east-1`;
- origens ativas do frontend e da API.

O runtime atual está em `../aws-static-ecs-us`. Não adicione VPC, ALB, ECS, buckets da aplicação, Lambda ou agendamentos a este state.

## State

```text
foton-ev/prod/global-edge/terraform.tfstate
```

Essa stack controla o domínio público em produção. Um `destroy`, um backend incorreto ou variáveis de origem vazias podem interromper todo o site.

## Operação

Crie `backend.hcl` e `prod.tfvars` locais a partir dos exemplos. Depois:

```powershell
terraform init -backend-config=backend.hcl
terraform state list
terraform validate
terraform plan -var-file=prod.tfvars -out=global-edge.tfplan
terraform show global-edge.tfplan
terraform apply global-edge.tfplan
```

As origens devem corresponder exatamente aos outputs `frontend_bucket_domain_name` e `api_load_balancer_domain_name` do runtime ativo. Aplique sempre o plano salvo que foi revisado.

## Evolução planejada

A futura modularização substituirá as variáveis com prefixo `us_` por um mapa de origens independente de região e backend. Essa refatoração deve preservar a distribuição, DNS e certificado com `moved` blocks e plano sem recriação. Veja [o plano de migração](../../docs/plano-migracao-lambda.md).
