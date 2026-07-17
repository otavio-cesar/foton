# Foton — runtime de produção em `us-east-1`

Esta é a stack regional atualmente ativa. Ela administra:

- bucket S3 privado do frontend;
- bucket S3 versionado do snapshot SQLite;
- VPC com duas sub-redes públicas e grupos de segurança;
- Application Load Balancer;
- API em ECS Fargate Spot;
- roles IAM e logs do CloudWatch.

CloudFront, Route 53 e ACM pertencem à stack global `../aws-static-ecs`.

## State

```text
foton-ev/prod/us-runtime/terraform.tfstate
```

Enquanto a persistência for SQLite, mantenha no máximo uma task da API. Duas tasks podem sobrescrever snapshots e perder orçamentos.

## Agendamento atual

O alvo e as ações de Application Auto Scaling foram criados diretamente na AWS porque a credencial de implantação não possui as permissões de leitura de tags exigidas pelo provider. Por isso, `schedule_enabled` deve permanecer `false` no `prod.tfvars` até esses recursos serem importados para o state ou a permissão ser corrigida.

- início: 08:00 em `America/Sao_Paulo`;
- parada: 00:00 em `America/Sao_Paulo`;
- capacidade: mínimo 0 e máximo 1.

Um plano com `schedule_enabled = true` pode colidir com os objetos existentes fora do state. Resolva a importação antes de habilitar essa variável.

## Operação

Crie `backend.hcl` e `prod.tfvars` locais a partir dos exemplos. Depois:

```powershell
terraform init -backend-config=backend.hcl
terraform state list
terraform validate
terraform plan -var-file=prod.tfvars -out=us-runtime.tfplan
terraform show us-runtime.tfplan
terraform apply us-runtime.tfplan
```

Revise com atenção qualquer alteração em buckets, rede, ALB, ECS, IAM e task definition. Aplique sempre o plano salvo que foi revisado.

## Evolução planejada

Esta raiz ainda carrega nomes e validações da migração para os Estados Unidos. O plano é extrair módulos reutilizáveis, parametrizar `runtime_region` e representar primeiro os mesmos recursos, sem substituição. A Lambda será adicionada depois como backend paralelo e opcional. Veja [o plano de migração](../../docs/plano-migracao-lambda.md).
