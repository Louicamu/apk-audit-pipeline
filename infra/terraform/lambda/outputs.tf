output "parse_findings_arn" {
  description = "Parse findings Lambda ARN"
  value       = aws_lambda_function.parse_findings.arn
}

output "save_report_arn" {
  description = "Save report Lambda ARN"
  value       = aws_lambda_function.save_report.arn
}
