output "state_bucket" {
  description = "S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "aws_region" {
  description = "AWS region for the backend."
  value       = var.aws_region
}

output "global_edge_state_key" {
  description = "S3 key for the global edge stack state."
  value       = "${var.project_name}/${var.environment}/global-edge/terraform.tfstate"
}

output "us_runtime_state_key" {
  description = "S3 key for the us-east-1 runtime stack state."
  value       = "${var.project_name}/${var.environment}/us-runtime/terraform.tfstate"
}

output "backend_config_global_edge" {
  description = "Backend config values for the global edge stack."
  value = {
    bucket       = aws_s3_bucket.state.bucket
    key          = "${var.project_name}/${var.environment}/global-edge/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

output "backend_config_us_runtime" {
  description = "Backend config values for the us-east-1 runtime stack."
  value = {
    bucket       = aws_s3_bucket.state.bucket
    key          = "${var.project_name}/${var.environment}/us-runtime/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}
