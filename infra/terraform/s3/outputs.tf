output "apk_uploads_bucket_arn" {
  description = "APK uploads bucket ARN"
  value       = aws_s3_bucket.apk_uploads.arn
}

output "apk_uploads_bucket_id" {
  description = "APK uploads bucket name"
  value       = aws_s3_bucket.apk_uploads.id
}

output "audit_reports_bucket_arn" {
  description = "Audit reports bucket ARN"
  value       = aws_s3_bucket.audit_reports.arn
}

output "audit_reports_bucket_id" {
  description = "Audit reports bucket name"
  value       = aws_s3_bucket.audit_reports.id
}

output "kms_key_arn" {
  description = "KMS CMK ARN"
  value       = aws_kms_key.s3.arn
}

output "kms_key_id" {
  description = "KMS CMK ID"
  value       = aws_kms_key.s3.key_id
}
