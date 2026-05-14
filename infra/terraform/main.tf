provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ─── Networking ───────────────────────────────────────────
module "networking" {
  source = "./networking"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

# ─── S3 Buckets + KMS ─────────────────────────────────────
module "s3" {
  source = "./s3"

  project_name     = var.project_name
  environment      = var.environment
  bucket_suffix    = random_id.bucket_suffix.hex
  expiration_days  = var.s3_expiration_days
}

# ─── DynamoDB ─────────────────────────────────────────────
module "dynamodb" {
  source = "./dynamodb"

  project_name = var.project_name
  environment  = var.environment
}

# ─── ECR Repositories ─────────────────────────────────────
module "ecr" {
  source = "./ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ─── IAM Roles + Policies ─────────────────────────────────
module "iam" {
  source = "./iam"

  project_name          = var.project_name
  environment           = var.environment
  apk_uploads_bucket_arn  = module.s3.apk_uploads_bucket_arn
  audit_reports_bucket_arn = module.s3.audit_reports_bucket_arn
  findings_table_arn      = module.dynamodb.findings_table_arn
  kms_key_arn            = module.s3.kms_key_arn
  sns_critical_topic_arn = module.observability.sns_critical_topic_arn
}

# ─── ECS Cluster + Task Definitions ───────────────────────
module "ecs" {
  source = "./ecs"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_tasks_sg_id       = module.networking.ecs_tasks_sg_id
  jadx_repo_url         = module.ecr.jadx_repo_url
  mobsf_repo_url        = module.ecr.mobsf_repo_url
  otel_repo_url         = module.ecr.otel_repo_url
  ecs_execution_role_arn = module.iam.ecs_execution_role_arn
  ecs_task_jadx_role_arn = module.iam.ecs_task_jadx_role_arn
  ecs_task_mobsf_role_arn = module.iam.ecs_task_mobsf_role_arn
  app_image_tag          = var.app_image_tag
  otel_image_tag         = var.otel_image_tag
  log_retention_days     = var.log_retention_days
  enable_spot            = var.enable_spot
  jadx_cpu               = var.jadx_cpu
  jadx_memory            = var.jadx_memory
  mobsf_cpu              = var.mobsf_cpu
  mobsf_memory           = var.mobsf_memory
  fargate_task_timeout   = var.fargate_task_timeout_seconds
}

# ─── Lambda Functions ─────────────────────────────────────
module "lambda" {
  source = "./lambda"

  project_name          = var.project_name
  environment           = var.environment
  audit_reports_bucket_arn = module.s3.audit_reports_bucket_arn
  audit_reports_bucket_id  = module.s3.audit_reports_bucket_id
  findings_table_name      = module.dynamodb.findings_table_name
  findings_table_arn       = module.dynamodb.findings_table_arn
  kms_key_arn             = module.s3.kms_key_arn
  lambda_role_arn         = module.iam.lambda_parse_role_arn
  subnet_ids              = module.networking.private_subnet_ids
  security_group_id       = module.networking.ecs_tasks_sg_id
}

# ─── Step Functions ───────────────────────────────────────
module "step_functions" {
  source = "./step-functions"

  project_name          = var.project_name
  environment           = var.environment
  ecs_cluster_arn       = module.ecs.cluster_arn
  jadx_task_def_arn     = module.ecs.jadx_task_def_arn
  mobsf_task_def_arn    = module.ecs.mobsf_task_def_arn
  parse_lambda_arn      = module.lambda.parse_findings_arn
  save_report_lambda_arn = module.lambda.save_report_arn
  ecs_tasks_sg_id       = module.networking.ecs_tasks_sg_id
  private_subnet_ids    = module.networking.private_subnet_ids
  apk_uploads_bucket_id  = module.s3.apk_uploads_bucket_id
  audit_reports_bucket_id = module.s3.audit_reports_bucket_id
  sns_critical_topic_arn = module.observability.sns_critical_topic_arn
  step_functions_role_arn = module.iam.step_functions_role_arn
}

# ─── Observability ────────────────────────────────────────
module "observability" {
  source = "./observability"

  project_name = var.project_name
  environment  = var.environment
  alarm_email  = var.alarm_email
}
