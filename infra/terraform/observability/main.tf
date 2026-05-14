locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ─── X-Ray Group ──────────────────────────────────────────
resource "aws_xray_group" "apk_audit" {
  group_name        = "${local.name_prefix}-apk-audit"
  filter_expression = "service(\"apk-jadx\") OR service(\"apk-mobsf\") OR service(\"${local.name_prefix}-state-machine\")"
}

resource "aws_xray_sampling_rule" "apk_audit" {
  rule_name      = "${local.name_prefix}-apk-audit"
  priority       = 1
  version        = 1
  reservoir_size = 1
  fixed_rate     = 1.0
  resource_arn   = "*"
  service_name   = "*"
  service_type   = "*"
  host           = "*"
  http_method    = "*"
  url_path       = "*"
}

# ─── SNS Topics ───────────────────────────────────────────
resource "aws_sns_topic" "critical_findings" {
  name              = "${local.name_prefix}-critical-findings"
  kms_master_key_id = "alias/aws/sns"

  tags = { Name = "${local.name_prefix}-critical-findings-topic" }
}

resource "aws_sns_topic" "pipeline_alerts" {
  name              = "${local.name_prefix}-pipeline-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = { Name = "${local.name_prefix}-pipeline-alerts-topic" }
}

resource "aws_sns_topic_subscription" "critical_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.critical_findings.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ─── CloudWatch Dashboard ─────────────────────────────────
resource "aws_cloudwatch_dashboard" "apk_audit" {
  dashboard_name = "${local.name_prefix}-apk-audit"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/States", "ExecutionsStarted", "StateMachineName", "${local.name_prefix}-apk-audit-pipeline", { stat = "Sum" }],
            ["AWS/States", "ExecutionsSucceeded", "StateMachineName", "${local.name_prefix}-apk-audit-pipeline", { stat = "Sum" }],
            ["AWS/States", "ExecutionsFailed", "StateMachineName", "${local.name_prefix}-apk-audit-pipeline", { stat = "Sum" }],
            ["AWS/States", "ExecutionsTimedOut", "StateMachineName", "${local.name_prefix}-apk-audit-pipeline", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Step Functions Executions"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${local.name_prefix}-cluster", { stat = "Average" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${local.name_prefix}-cluster", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ECS Task Resource Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/X-Ray", "TraceCount", { stat = "Sum", label = "Total Traces" }],
            ["AWS/X-Ray", "ThrottleCount", { stat = "Sum", label = "Throttled" }],
            ["AWS/X-Ray", "FaultCount", { stat = "Sum", label = "Faults" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "X-Ray Trace Statistics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${local.name_prefix}-parse-findings", { stat = "Sum" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${local.name_prefix}-parse-findings", { stat = "Average" }],
            ["AWS/Lambda", "Errors", "FunctionName", "${local.name_prefix}-parse-findings", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Lambda — Parse Findings"
          period  = 300
        }
      }
    ]
  })
}

# ─── CloudWatch Alarm: Pipeline Failures ──────────────────
resource "aws_cloudwatch_metric_alarm" "pipeline_failures" {
  alarm_name          = "${local.name_prefix}-pipeline-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when the APK audit pipeline fails"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    StateMachineName = "${local.name_prefix}-apk-audit-pipeline"
  }

  treat_missing_data = "notBreaching"
}

# ─── CloudWatch Alarm: Fargate Spot Interruptions ─────────
resource "aws_cloudwatch_metric_alarm" "fargate_spot_interruptions" {
  alarm_name          = "${local.name_prefix}-fargate-spot-interruptions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FargateSpotInterruptionCount"
  namespace           = "AWS/ECS"
  period              = 3600
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "High rate of Fargate Spot interruptions — consider increasing on-demand ratio"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    ClusterName = "${local.name_prefix}-cluster"
  }
}

data "aws_region" "current" {}
