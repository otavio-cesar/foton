output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "web_load_balancer" {
  value = try(kubernetes_service.web.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "api_image" {
  value = local.api_image
}

output "web_image" {
  value = local.web_image
}
