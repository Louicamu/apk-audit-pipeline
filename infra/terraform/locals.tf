locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "apk-security-audit"
  }

  s3_bucket_names = {
    apk_uploads   = "${local.name_prefix}-apk-uploads-${random_id.bucket_suffix.hex}"
    audit_reports = "${local.name_prefix}-audit-reports-${random_id.bucket_suffix.hex}"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 6
}
