variable "aws_region" {
  description = "Default AWS region used by the global edge stack."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
  default     = "foton-ev"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "custom_domain_names" {
  description = "Custom domain names for CloudFront. Certificate is created in us-east-1."
  type        = list(string)
  default     = ["higgsenergia.com.br", "www.higgsenergia.com.br"]
}

variable "enable_custom_domain" {
  description = "Use the ACM certificate and aliases on CloudFront. Enable only after DNS validation is complete."
  type        = bool
  default     = false
}

variable "manage_route53_zone" {
  description = "Create and manage the Route 53 hosted zone for the custom domain."
  type        = bool
  default     = true
}

variable "active_runtime_region" {
  description = "Regional runtime selected by the existing global CloudFront distribution."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.active_runtime_region == "us-east-1"
    error_message = "The active runtime must be in us-east-1."
  }
}

variable "us_frontend_origin_domain_name" {
  description = "S3 regional domain for the parallel frontend in us-east-1."
  type        = string
  default     = ""
}

variable "us_api_origin_domain_name" {
  description = "ALB domain for the parallel API in us-east-1."
  type        = string
  default     = ""
}
