locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ─── KMS Customer Managed Key ─────────────────────────────
resource "aws_kms_key" "s3" {
  description             = "KMS CMK for S3 bucket encryption - ${local.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3Encryption"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:s3:arn" = [
              "arn:aws:s3:::${local.name_prefix}-apk-uploads-${var.bucket_suffix}/*",
              "arn:aws:s3:::${local.name_prefix}-audit-reports-${var.bucket_suffix}/*"
            ]
          }
        }
      }
    ]
  })

  tags = { Name = "${local.name_prefix}-s3-kms-key" }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# ─── S3 Buckets ───────────────────────────────────────────
resource "aws_s3_bucket" "apk_uploads" {
  bucket = "${local.name_prefix}-apk-uploads-${var.bucket_suffix}"

  tags = { Name = "${local.name_prefix}-apk-uploads" }
}

resource "aws_s3_bucket" "audit_reports" {
  bucket = "${local.name_prefix}-audit-reports-${var.bucket_suffix}"

  tags = { Name = "${local.name_prefix}-audit-reports" }
}

# ─── Public Access Block (both buckets) ───────────────────
resource "aws_s3_bucket_public_access_block" "apk_uploads" {
  bucket                  = aws_s3_bucket.apk_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "audit_reports" {
  bucket                  = aws_s3_bucket.audit_reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── AES-256 Encryption with KMS ──────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "apk_uploads" {
  bucket = aws_s3_bucket.apk_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_reports" {
  bucket = aws_s3_bucket.audit_reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

# ─── Versioning ───────────────────────────────────────────
resource "aws_s3_bucket_versioning" "apk_uploads" {
  bucket = aws_s3_bucket.apk_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "audit_reports" {
  bucket = aws_s3_bucket.audit_reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ─── Lifecycle: Intelligent-Tiering + 90-day expiration ────
resource "aws_s3_bucket_lifecycle_configuration" "apk_uploads" {
  bucket = aws_s3_bucket.apk_uploads.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {}

    expiration {
      days                         = var.expiration_days
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_reports" {
  bucket = aws_s3_bucket.audit_reports.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {}

    expiration {
      days                         = var.expiration_days
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ─── EventBridge notification (triggers Step Functions) ───
resource "aws_s3_bucket_notification" "apk_uploads" {
  bucket      = aws_s3_bucket.apk_uploads.id
  eventbridge = true
}

data "aws_caller_identity" "current" {}
