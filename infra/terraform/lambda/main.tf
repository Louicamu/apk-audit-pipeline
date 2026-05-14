locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "archive_file" "parse_findings" {
  type        = "zip"
  source_dir  = "${path.module}/functions/parse-findings"
  output_path = "${path.module}/functions/parse-findings.zip"
}

resource "aws_lambda_function" "parse_findings" {
  function_name    = "${local.name_prefix}-parse-findings"
  description      = "Parse MobSF output, extract HIGH/CRITICAL findings, write to DynamoDB"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.11"
  architectures    = ["arm64"]
  timeout          = 120
  memory_size      = 1024
  filename         = data.archive_file.parse_findings.output_path
  source_code_hash = data.archive_file.parse_findings.output_base64sha256

  environment {
    variables = {
      FINDINGS_TABLE_NAME = var.findings_table_name
      REPORTS_BUCKET      = var.audit_reports_bucket_id
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  tags = { Name = "${local.name_prefix}-parse-findings-lambda" }
}

# Save-report Lambda — same code, different handler mode triggered by Step Functions
resource "aws_lambda_function" "save_report" {
  function_name    = "${local.name_prefix}-save-report"
  description      = "Save final audit report JSON to S3"
  role             = var.lambda_role_arn
  handler          = "index.save_report_handler"
  runtime          = "python3.11"
  architectures    = ["arm64"]
  timeout          = 60
  memory_size      = 512
  filename         = data.archive_file.parse_findings.output_path
  source_code_hash = data.archive_file.parse_findings.output_base64sha256

  environment {
    variables = {
      FINDINGS_TABLE_NAME = var.findings_table_name
      REPORTS_BUCKET      = var.audit_reports_bucket_id
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  tags = { Name = "${local.name_prefix}-save-report-lambda" }
}
