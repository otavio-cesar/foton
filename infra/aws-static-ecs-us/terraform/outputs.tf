output "frontend_bucket" {
  description = "Target frontend bucket in us-east-1."
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_domain_name" {
  description = "Regional domain used as the future CloudFront origin."
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "sqlite_bucket" {
  description = "Target SQLite snapshot bucket in us-east-1."
  value       = aws_s3_bucket.sqlite.bucket
}

output "api_load_balancer_url" {
  description = "Direct target ALB URL."
  value       = "http://${aws_lb.api.dns_name}"
}

output "api_load_balancer_domain_name" {
  description = "Target ALB domain used as the future CloudFront origin."
  value       = aws_lb.api.dns_name
}

output "ecs_cluster_name" {
  description = "Target ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Target ECS service name."
  value       = aws_ecs_service.api.name
}

output "ecs_task_definition_arn" {
  description = "Target API task definition."
  value       = aws_ecs_task_definition.api.arn
}
