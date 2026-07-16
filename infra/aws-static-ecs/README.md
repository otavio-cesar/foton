# Foton — camada global

Esta stack administra somente os componentes globais compartilhados:

- distribuição e OAC do CloudFront;
- zona e registros do Route 53;
- certificado ACM do CloudFront em `us-east-1`;
- seleção das origens do frontend e da API.

O runtime regional está separado em `infra/aws-static-ecs-us`. Não adicione
ALB, ECS, VPC, buckets da aplicação ou agendamentos a este state.

## Backend

O state fica nos Estados Unidos:

```text
foton-ev/prod/global-edge/terraform.tfstate
```

Use sempre o arquivo de produção explícito e aplique um plano salvo:

```powershell
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -var-file=prod.tfvars -out=global-edge.tfplan
terraform apply global-edge.tfplan
```

As origens ativas devem ser os outputs `frontend_bucket_domain_name` e
`api_load_balancer_domain_name` da stack regional.
