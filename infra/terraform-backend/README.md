# Terraform backend de produção (`us-east-1`)

Este bootstrap cria o bucket usado pelos states remotos:

- S3 privado, criptografado e versionado;
- lock nativo do backend S3 com `use_lockfile = true`.

O bootstrap mantém state local porque ele próprio cria o backend. Preserve e proteja esse arquivo local; perder o state do bootstrap não apaga o bucket, mas dificulta sua manutenção segura.

## States atuais

- `foton-ev/prod/global-edge/terraform.tfstate`: CloudFront, Route 53 e ACM;
- `foton-ev/prod/us-runtime/terraform.tfstate`: frontend S3, ALB, ECS, rede e SQLite/S3 em `us-east-1`.

Exemplo de `backend.hcl` local:

```hcl
bucket       = "replace-with-state-bucket"
key          = "foton-ev/prod/global-edge/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

`backend.hcl`, `prod.tfvars`, states e planos não devem ser versionados.

## Validação do bootstrap

Na pasta `bootstrap`:

```powershell
terraform init
terraform state list
terraform validate
terraform plan -var-file=prod.tfvars -out=backend.tfplan
terraform show backend.tfplan
```

Não execute `destroy`: isso removeria o backend usado pelas stacks de produção. Uma eventual nova região de runtime pode continuar usando esse bucket; a região do state não precisa ser igual à região dos recursos gerenciados.

Novas chaves regionais devem seguir o desenho definido no [plano de modularização](../../docs/plano-migracao-lambda.md).
