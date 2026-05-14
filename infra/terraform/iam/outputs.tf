output "step_functions_role_arn" {
  description = "Step Functions execution role ARN"
  value       = aws_iam_role.step_functions_execution.arn
}

output "ecs_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_jadx_role_arn" {
  description = "ECS jadx task role ARN"
  value       = aws_iam_role.ecs_task_jadx.arn
}

output "ecs_task_mobsf_role_arn" {
  description = "ECS MobSF task role ARN"
  value       = aws_iam_role.ecs_task_mobsf.arn
}

output "lambda_parse_role_arn" {
  description = "Lambda parse-findings + save-report role ARN"
  value       = aws_iam_role.lambda_parse.arn
}
