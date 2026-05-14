output "findings_table_arn" {
  description = "Findings table ARN"
  value       = aws_dynamodb_table.findings.arn
}

output "findings_table_name" {
  description = "Findings table name"
  value       = aws_dynamodb_table.findings.name
}

output "severity_gsi_name" {
  description = "Severity-index GSI name"
  value       = "severity-index"
}
