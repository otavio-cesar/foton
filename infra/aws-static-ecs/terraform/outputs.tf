output "frontend_bucket" {
  description = "Private S3 bucket for Angular build artifacts."
  value       = aws_s3_bucket.frontend.bucket
}

output "sqlite_bucket" {
  description = "Private S3 bucket that stores the SQLite snapshot."
  value       = aws_s3_bucket.sqlite.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution id."
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_url" {
  description = "Public CloudFront URL."
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "custom_domain_urls" {
  description = "Custom domain URLs configured for CloudFront when enable_custom_domain is true."
  value       = [for domain in var.custom_domain_names : "https://${domain}"]
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront."
  value       = length(aws_acm_certificate.frontend) > 0 ? aws_acm_certificate.frontend[0].arn : null
}

output "acm_dns_validation_records" {
  description = "Create these DNS CNAME records where the domain DNS is hosted, then wait for ACM to issue the certificate."
  value = length(aws_acm_certificate.frontend) > 0 ? [
    for option in aws_acm_certificate.frontend[0].domain_validation_options : {
      domain = option.domain_name
      name   = option.resource_record_name
      type   = option.resource_record_type
      value  = option.resource_record_value
    }
  ] : []
}

output "route53_zone_id" {
  description = "Route 53 hosted zone id for the custom domain."
  value       = length(aws_route53_zone.frontend) > 0 ? aws_route53_zone.frontend[0].zone_id : null
}

output "route53_name_servers" {
  description = "Configure these name servers at Registro.br for the domain."
  value       = length(aws_route53_zone.frontend) > 0 ? aws_route53_zone.frontend[0].name_servers : []
}

output "api_load_balancer_url" {
  description = "Direct API load balancer URL."
  value       = "http://${aws_lb.api.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS API service name."
  value       = aws_ecs_service.api.name
}
