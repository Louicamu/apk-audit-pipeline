variable "project_name" { type = string }
variable "environment" { type = string }
variable "apk_uploads_bucket_arn" { type = string }
variable "audit_reports_bucket_arn" { type = string }
variable "findings_table_arn" { type = string }
variable "kms_key_arn" { type = string }
variable "sns_critical_topic_arn" { type = string }
