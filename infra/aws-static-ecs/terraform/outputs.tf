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
  description = "ACM validation DNS records."
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
  description = "Authoritative name servers for the domain."
  value       = length(aws_route53_zone.frontend) > 0 ? aws_route53_zone.frontend[0].name_servers : []
}

output "active_runtime_region" {
  description = "Regional runtime currently selected by CloudFront."
  value       = var.active_runtime_region
}

output "active_frontend_origin_domain_name" {
  description = "Frontend origin currently selected by CloudFront."
  value       = var.us_frontend_origin_domain_name
}

output "active_api_origin_domain_name" {
  description = "API origin currently selected by CloudFront."
  value       = var.us_api_origin_domain_name
}
