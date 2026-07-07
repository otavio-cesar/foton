# Terraform Backend Bootstrap

Este bootstrap cria os recursos usados como backend remoto do Terraform:

- Bucket S3 privado, criptografado e versionado para `terraform.tfstate`.
- Tabela DynamoDB para lock do state.

O bootstrap fica com state local inicialmente, porque ele cria o backend que as outras stacks vao usar.

## Criar backend

```powershell
.\scripts\terraform-backend-bootstrap-apply.ps1
```

Depois copie os valores de output para um arquivo `backend.hcl` local na stack que vai usar o backend.

Exemplo para `infra/aws-static-ecs/terraform/backend.hcl`:

```hcl
bucket         = "bucket-gerado-pelo-bootstrap"
key            = "foton-ev/prod/aws-static-ecs/terraform.tfstate"
region         = "sa-east-1"
dynamodb_table = "foton-ev-prod-tfstate-lock"
encrypt        = true
```

O arquivo `backend.hcl` deve ficar fora do Git.
