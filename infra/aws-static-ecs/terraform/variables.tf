variable "aws_region" {
  description = "AWS region for regional resources."
  type        = string
  default     = "sa-east-1"
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

variable "api_image" {
  description = "Docker Hub image for the .NET API."
  type        = string
  default     = "otavioc31/foton-api:v2"
}

variable "api_cpu" {
  description = "ECS task CPU units."
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "ECS task memory in MiB."
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Desired task count. Keep 1 while using SQLite file snapshots."
  type        = number
  default     = 1

  validation {
    condition     = var.api_desired_count == 1
    error_message = "SQLite file snapshots are safe only with api_desired_count = 1."
  }
}

variable "sqlite_object_key" {
  description = "S3 object key used to store the SQLite database snapshot."
  type        = string
  default     = "sqlite/foton.db"
}

variable "allowed_origins" {
  description = "CORS origins allowed by the API."
  type        = list(string)
  default     = ["*"]
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
