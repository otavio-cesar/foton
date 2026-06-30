# Plano de entrega

## Fase 1 - Base publica do projeto

- Criar monorepo com frontend, backend, infraestrutura e deploy.
- Definir identidade inicial da Foton Energia Fotovoltaica com paleta verde/amarelo.
- Implementar landing page responsiva com chamada para orcamento.
- Implementar endpoint inicial de orcamento na API.
- Persistir orcamentos em banco relacional via contrato de repositorio.
- Preparar Dockerfiles, Kubernetes, Terraform AWS e Ansible.

## Fase 2 - Integracoes reais

- Configurar Amazon RDS PostgreSQL com credenciais via Secrets Manager.
- Configurar ECR, EKS, Load Balancer Controller e DNS.
- Ligar formulario a assistente virtual real por webhook ou fila.
- Adicionar autenticacao administrativa para consulta de orcamentos.
- Adicionar observabilidade com logs estruturados, health checks e metricas.

## Fase 3 - Qualidade e operacao

- Criar pipeline CI/CD no GitHub Actions.
- Rodar testes unitarios e de integracao.
- Adicionar testes e2e do formulario.
- Definir backups, retencao e alarmes do RDS.
- Documentar runbook de deploy e rollback.

## Decisoes iniciais

- A API salva o orcamento antes de acionar a assistente virtual.
- A assistente virtual sera acoplada por interface para permitir webhook, fila ou provider externo.
- O dominio nao depende de AWS, Entity Framework, HTTP ou frameworks de UI.
- A infraestrutura usa Terraform para recursos cloud e Ansible apenas para configuracao de maquinas quando houver hosts a configurar.
