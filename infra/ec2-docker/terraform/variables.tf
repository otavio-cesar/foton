variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project resource prefix."
  type        = string
  default     = "foton-ev"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the EC2 instance."
  type        = string
}

variable "public_key_path" {
  description = "Optional existing public key path. If empty, Terraform creates a local key pair under generated/."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 30
}
