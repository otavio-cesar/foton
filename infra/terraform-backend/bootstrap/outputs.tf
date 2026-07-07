output "state_bucket" {
  description = "S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "lock_table" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.lock.name
}

output "aws_region" {
  description = "AWS region for the backend."
  value       = var.aws_region
}

output "static_ecs_state_key" {
  description = "S3 key for the static ECS stack state."
  value       = "${var.project_name}/${var.environment}/aws-static-ecs/terraform.tfstate"
}

output "backend_config_static_ecs" {
  description = "Backend config values for infra/aws-static-ecs/terraform."
  value = {
    bucket         = aws_s3_bucket.state.bucket
    key            = "${var.project_name}/${var.environment}/aws-static-ecs/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.lock.name
    encrypt        = true
  }
}
