output "jadx_repo_url" {
  description = "ECR repository URL for jadx"
  value       = aws_ecr_repository.jadx.repository_url
}

output "mobsf_repo_url" {
  description = "ECR repository URL for MobSF"
  value       = aws_ecr_repository.mobsf.repository_url
}

output "otel_repo_url" {
  description = "ECR repository URL for OTel collector"
  value       = aws_ecr_repository.otel.repository_url
}

output "jadx_repo_arn" {
  description = "ECR repository ARN for jadx"
  value       = aws_ecr_repository.jadx.arn
}

output "mobsf_repo_arn" {
  description = "ECR repository ARN for MobSF"
  value       = aws_ecr_repository.mobsf.arn
}
