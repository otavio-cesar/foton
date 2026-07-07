# Foton AWS Static + ECS

Esta stack substitui a EC2 por:

- S3 privado para o build estatico do Angular.
- CloudFront como entrada publica do site.
- ALB para a API .NET.
- ECS Fargate Spot para executar a API via imagem do Docker Hub.
- S3 privado e versionado para snapshots do SQLite.

Enquanto o banco for SQLite em arquivo, mantenha `api_desired_count = 1`.
Mais de uma task pode sobrescrever o snapshot no S3.

## Fluxo de publicacao

1. Publicar a imagem da API no Docker Hub.
2. Aplicar Terraform em `infra/aws-static-ecs/terraform`.
3. Buildar o Angular.
4. Sincronizar o conteudo de `apps/web/dist/foton-landing-page/browser` para o bucket `frontend_bucket`.
5. Criar uma invalidacao no CloudFront.

O frontend usa chamadas relativas para `/api`, e o CloudFront encaminha `/api/*` e `/health` para o ALB.

## Dominio proprio

O certificado do CloudFront deve ficar no ACM em `us-east-1`.

Fluxo recomendado usando Route 53:

1. Aplicar Terraform com `enable_custom_domain = false`.
2. Copiar os outputs `route53_name_servers`.
3. Informar esses servidores DNS no Registro.br.
4. Aguardar a delegacao DNS propagar e o certificado ACM ficar `ISSUED`.
5. Aplicar novamente com `enable_custom_domain = true`.
