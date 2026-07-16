variable "aws_region" {
  description = "AWS region for the target runtime."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "This migration stack is intentionally restricted to us-east-1."
  }
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
  default     = "foton-ev"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "api_image" {
  description = "Immutable Docker Hub image for the .NET API."
  type        = string
  default     = "otavioc31/foton-api:4c60781"

  validation {
    condition     = !endswith(var.api_image, ":latest")
    error_message = "Use an immutable image tag instead of latest."
  }
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
  description = "Initial ECS task count. Keep zero until the target is ready for validation."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.api_desired_count)
    error_message = "SQLite supports only zero or one running API task."
  }
}

variable "sqlite_object_key" {
  description = "S3 object key used for the SQLite snapshot."
  type        = string
  default     = "sqlite/foton.db"
}

variable "allowed_origins" {
  description = "CORS origins allowed by the API."
  type        = list(string)
  default = [
    "https://higgsenergia.com.br",
    "https://www.higgsenergia.com.br"
  ]
}

variable "cloudfront_distribution_id" {
  description = "Existing CloudFront distribution allowed to read the target frontend bucket."
  type        = string
}

variable "schedule_enabled" {
  description = "Create the ECS scheduled scaling target and actions."
  type        = bool
  default     = true
}

variable "schedule_timezone" {
  description = "Timezone used by scheduled scaling."
  type        = string
  default     = "America/Sao_Paulo"
}

variable "api_start_schedule" {
  description = "Daily schedule that starts the API."
  type        = string
  default     = "cron(0 8 * * ? *)"
}

variable "api_stop_schedule" {
  description = "Daily schedule that stops the API."
  type        = string
  default     = "cron(0 0 * * ? *)"
}
