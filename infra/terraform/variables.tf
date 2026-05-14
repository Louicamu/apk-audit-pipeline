variable "project_name" {
  description = "Project name tag for all resources"
  type        = string
  default     = "apk-audit"
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnet distribution"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (one per AZ)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "app_image_tag" {
  description = "Docker image tag for application containers"
  type        = string
  default     = "latest"
}

variable "otel_image_tag" {
  description = "OpenTelemetry collector image tag"
  type        = string
  default     = "0.114.0"
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 7
}

variable "s3_expiration_days" {
  description = "Days before S3 objects expire"
  type        = number
  default     = 90
}

variable "enable_spot" {
  description = "Use FARGATE_SPOT capacity provider for cost savings"
  type        = bool
  default     = true
}

variable "jadx_cpu" {
  description = "CPU units for jadx Fargate task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "jadx_memory" {
  description = "Memory for jadx Fargate task (MiB)"
  type        = number
  default     = 4096
}

variable "mobsf_cpu" {
  description = "CPU units for MobSF Fargate task"
  type        = number
  default     = 2048
}

variable "mobsf_memory" {
  description = "Memory for MobSF Fargate task (MiB)"
  type        = number
  default     = 8192
}

variable "alarm_email" {
  description = "Email for critical findings SNS notifications"
  type        = string
  default     = ""
}

variable "fargate_task_timeout_seconds" {
  description = "Max duration for Fargate tasks before timeout"
  type        = number
  default     = 900
}
