locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ─── CloudWatch Log Groups ────────────────────────────────
resource "aws_cloudwatch_log_group" "jadx" {
  name              = "/ecs/${local.name_prefix}-jadx"
  retention_in_days = var.log_retention_days
  kms_key_id        = null
  tags              = { Name = "${local.name_prefix}-jadx-logs" }
}

resource "aws_cloudwatch_log_group" "mobsf" {
  name              = "/ecs/${local.name_prefix}-mobsf"
  retention_in_days = var.log_retention_days
  kms_key_id        = null
  tags              = { Name = "${local.name_prefix}-mobsf-logs" }
}

resource "aws_cloudwatch_log_group" "otel" {
  name              = "/ecs/${local.name_prefix}-otel-sidecar"
  retention_in_days = var.log_retention_days
  kms_key_id        = null
  tags              = { Name = "${local.name_prefix}-otel-logs" }
}

# ─── ECS Cluster ──────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-ecs-cluster" }
}

# Capacity providers: FARGATE + FARGATE_SPOT
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = var.enable_spot ? ["FARGATE", "FARGATE_SPOT"] : ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = var.enable_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = var.enable_spot ? 2 : 1
    base              = 0
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }
}

# ─── jadx Task Definition ─────────────────────────────────
resource "aws_ecs_task_definition" "jadx" {
  family                   = "${local.name_prefix}-jadx"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.jadx_cpu)
  memory                   = tostring(var.jadx_memory)
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_jadx_role_arn

  container_definitions = templatefile("${path.module}/task-definitions/jadx-task-def.json", {
    ecr_repo_url = var.jadx_repo_url
    otel_repo_url = var.otel_repo_url
    app_image_tag = var.app_image_tag
    otel_image_tag = var.otel_image_tag
    log_group_jadx = aws_cloudwatch_log_group.jadx.name
    log_group_otel = aws_cloudwatch_log_group.otel.name
    log_region = var.aws_region
    otel_config = base64encode(file("${path.module}/otel-config.yaml"))
  })

  tags = { Name = "${local.name_prefix}-jadx-taskdef" }
}

# ─── MobSF Task Definition ────────────────────────────────
resource "aws_ecs_task_definition" "mobsf" {
  family                   = "${local.name_prefix}-mobsf"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.mobsf_cpu)
  memory                   = tostring(var.mobsf_memory)
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_mobsf_role_arn

  container_definitions = templatefile("${path.module}/task-definitions/mobsf-task-def.json", {
    ecr_repo_url = var.mobsf_repo_url
    otel_repo_url = var.otel_repo_url
    app_image_tag = var.app_image_tag
    otel_image_tag = var.otel_image_tag
    log_group_mobsf = aws_cloudwatch_log_group.mobsf.name
    log_group_otel = aws_cloudwatch_log_group.otel.name
    log_region = var.aws_region
    otel_config = base64encode(file("${path.module}/otel-config.yaml"))
  })

  tags = { Name = "${local.name_prefix}-mobsf-taskdef" }
}
