locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ─── Step Functions State Machine ─────────────────────────
resource "aws_sfn_state_machine" "apk_audit" {
  name     = "${local.name_prefix}-apk-audit-pipeline"
  role_arn = var.step_functions_role_arn
  type     = "STANDARD"

  definition = templatefile("${path.module}/state-machine-definition.json", {
    ecs_cluster_arn        = var.ecs_cluster_arn
    jadx_task_def_arn      = var.jadx_task_def_arn
    mobsf_task_def_arn     = var.mobsf_task_def_arn
    parse_lambda_arn       = var.parse_lambda_arn
    save_report_lambda_arn = var.save_report_lambda_arn
    ecs_tasks_sg_id        = var.ecs_tasks_sg_id
    private_subnet_0       = var.private_subnet_ids[0]
    private_subnet_1       = var.private_subnet_ids[1]
    apk_uploads_bucket     = var.apk_uploads_bucket_id
    audit_reports_bucket   = var.audit_reports_bucket_id
    sns_critical_topic_arn = var.sns_critical_topic_arn
    name_prefix            = local.name_prefix
  })

  tracing_configuration {
    enabled = true
  }

  logging_configuration {
    level                  = "ERROR"
    include_execution_data = true
    log_destination        = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
  }

  tags = { Name = "${local.name_prefix}-apk-audit-sfn" }
}

# ─── EventBridge Rule: S3 → Step Functions ────────────────
resource "aws_cloudwatch_event_rule" "s3_apk_upload" {
  name        = "${local.name_prefix}-s3-apk-upload"
  description = "Trigger Step Functions when APK is uploaded to S3"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail_type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.apk_uploads_bucket_id]
      }
      object = {
        key = [{ suffix = ".apk" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "step_functions" {
  rule      = aws_cloudwatch_event_rule.s3_apk_upload.name
  target_id = "${local.name_prefix}-apk-audit-trigger"
  arn       = aws_sfn_state_machine.apk_audit.arn
  role_arn  = var.step_functions_role_arn
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
