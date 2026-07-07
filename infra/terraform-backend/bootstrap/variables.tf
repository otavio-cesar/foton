variable "aws_region" {
  description = "AWS region for the Terraform backend resources."
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project name used in backend resource names."
  type        = string
  default     = "foton-ev"
}

variable "environment" {
  description = "Environment used in backend resource names."
  type        = string
  default     = "prod"
}

variable "state_bucket_name" {
  description = "Optional explicit S3 bucket name. Leave empty to use a generated name with bucket_prefix."
  type        = string
  default     = ""
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
  default     = ""
}

variable "force_destroy_state_bucket" {
  description = "Allows Terraform to delete the state bucket even when it contains objects. Keep false for real use."
  type        = bool
  default     = false
}
