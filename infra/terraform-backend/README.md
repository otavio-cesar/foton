# Terraform Backend Bootstrap (`us-east-1`)

Este bootstrap cria os recursos usados como backend remoto do Terraform:

- Bucket S3 privado, criptografado e versionado para `terraform.tfstate`.
- Lock nativo do backend S3 (`use_lockfile = true`).

O bootstrap fica com state local, porque ele cria o backend que as outras stacks usam.

## Criar backend

```powershell
.\scripts\terraform-backend-bootstrap-apply.ps1
```

Os dois estados remotos ficam separados:

- `foton-ev/prod/global-edge/terraform.tfstate`: CloudFront, Route 53 e certificado.
- `foton-ev/prod/us-runtime/terraform.tfstate`: frontend S3, ALB, ECS e rede em `us-east-1`.

Exemplo de `backend.hcl` local:

```hcl
bucket         = "foton-ev-prod-us-tfstate-045444243386"
key            = "foton-ev/prod/global-edge/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
use_lockfile   = true
```

O arquivo `backend.hcl` deve ficar fora do Git.
