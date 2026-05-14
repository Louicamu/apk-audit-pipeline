output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for Fargate tasks"
  value       = module.networking.private_subnet_ids
}

output "apk_uploads_bucket_name" {
  description = "S3 bucket for APK uploads"
  value       = module.s3.apk_uploads_bucket_id
}

output "audit_reports_bucket_name" {
  description = "S3 bucket for audit reports"
  value       = module.s3.audit_reports_bucket_id
}

output "kms_key_arn" {
  description = "KMS CMK ARN for S3 encryption"
  value       = module.s3.kms_key_arn
}

output "findings_table_name" {
  description = "DynamoDB findings table name"
  value       = module.dynamodb.findings_table_name
}

output "jadx_repo_url" {
  description = "ECR repository URL for jadx"
  value       = module.ecr.jadx_repo_url
}

output "mobsf_repo_url" {
  description = "ECR repository URL for MobSF"
  value       = module.ecr.mobsf_repo_url
}

output "parse_lambda_arn" {
  description = "Parse findings Lambda function ARN"
  value       = module.lambda.parse_findings_arn
}

output "state_machine_arn" {
  description = "Step Functions state machine ARN"
  value       = module.step_functions.state_machine_arn
}

output "sns_critical_topic_arn" {
  description = "SNS topic ARN for critical findings"
  value       = module.observability.sns_critical_topic_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}
