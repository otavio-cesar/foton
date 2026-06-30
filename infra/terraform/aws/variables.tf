variable "aws_region" {
  description = "AWS region for Foton infrastructure."
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project resource prefix."
  type        = string
  default     = "foton-ev"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}

variable "dockerhub_namespace" {
  description = "Docker Hub namespace or user that owns the images."
  type        = string
}

variable "api_image_name" {
  description = "Docker Hub API image repository name."
  type        = string
  default     = "foton-api"
}

variable "web_image_name" {
  description = "Docker Hub web image repository name."
  type        = string
  default     = "foton-web"
}

variable "image_tag" {
  description = "Image tag deployed to Kubernetes."
  type        = string
  default     = "latest"
}

variable "db_username" {
  description = "RDS PostgreSQL username."
  type        = string
  default     = "foton"
}

variable "db_password" {
  description = "RDS PostgreSQL password."
  type        = string
  sensitive   = true
}

variable "eks_node_instance_types" {
  description = "Instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "eks_cluster_version" {
  description = "Kubernetes version used by EKS."
  type        = string
  default     = "1.36"
}

variable "eks_desired_size" {
  description = "Desired number of EKS nodes."
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "Minimum number of EKS nodes."
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "Maximum number of EKS nodes."
  type        = number
  default     = 3
}
