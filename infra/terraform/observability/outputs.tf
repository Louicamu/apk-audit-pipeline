output "sns_critical_topic_arn" {
  description = "SNS topic ARN for critical findings"
  value       = aws_sns_topic.critical_findings.arn
}

output "sns_alert_topic_arn" {
  description = "SNS topic ARN for pipeline alerts"
  value       = aws_sns_topic.pipeline_alerts.arn
}
