locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ─── 1. Step Functions Execution Role ─────────────────────
resource "aws_iam_role" "step_functions_execution" {
  name = "${local.name_prefix}-sfn-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.${data.aws_region.current.name}.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-sfn-execution-role" }
}

resource "aws_iam_role_policy" "step_functions_execution" {
  name = "${local.name_prefix}-sfn-execution-policy"
  role = aws_iam_role.step_functions_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ]
        Resource = [
          "${replace(var.apk_uploads_bucket_arn, ":s3:", ":ecs:")}:task-definition/${local.name_prefix}-*:*",
          "${replace(var.apk_uploads_bucket_arn, ":s3:", ":ecs:")}:task-definition/${local.name_prefix}-*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task_jadx.arn,
          aws_iam_role.ecs_task_mobsf.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.sns_critical_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = [
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/${local.name_prefix}-*"
        ]
      }
    ]
  })
}

# ─── 2. ECS Task Execution Role (pull images, write logs) ─
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-ecs-execution-role" }
}

resource "aws_iam_role_policy" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-policy"
  role = aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${local.name_prefix}-*:*"
      }
    ]
  })
}

# ─── 3. ECS jadx Task Role ────────────────────────────────
resource "aws_iam_role" "ecs_task_jadx" {
  name = "${local.name_prefix}-ecs-task-jadx"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-ecs-task-jadx-role" }
}

resource "aws_iam_role_policy" "ecs_task_jadx" {
  name = "${local.name_prefix}-ecs-task-jadx-policy"
  role = aws_iam_role.ecs_task_jadx.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${var.apk_uploads_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "${var.audit_reports_bucket_arn}",
          "${var.audit_reports_bucket_arn}/decompiled/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─── 4. ECS MobSF Task Role ───────────────────────────────
resource "aws_iam_role" "ecs_task_mobsf" {
  name = "${local.name_prefix}-ecs-task-mobsf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-ecs-task-mobsf-role" }
}

resource "aws_iam_role_policy" "ecs_task_mobsf" {
  name = "${local.name_prefix}-ecs-task-mobsf-policy"
  role = aws_iam_role.ecs_task_mobsf.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = [
          "${var.apk_uploads_bucket_arn}/*",
          "${var.audit_reports_bucket_arn}/decompiled/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "${var.audit_reports_bucket_arn}",
          "${var.audit_reports_bucket_arn}/mobsf-output/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─── 5. Lambda Parse + Save-Report Role ───────────────────
resource "aws_iam_role" "lambda_parse" {
  name = "${local.name_prefix}-lambda-parse"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-lambda-parse-role" }
}

resource "aws_iam_role_policy" "lambda_parse" {
  name = "${local.name_prefix}-lambda-parse-policy"
  role = aws_iam_role.lambda_parse.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${var.audit_reports_bucket_arn}/mobsf-output/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = [
          "${var.audit_reports_bucket_arn}/final-reports/*",
          "${var.audit_reports_bucket_arn}/decompiled/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Resource = var.findings_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
