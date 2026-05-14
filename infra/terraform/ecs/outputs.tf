output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "jadx_task_def_arn" {
  description = "jadx task definition ARN"
  value       = aws_ecs_task_definition.jadx.arn
}

output "mobsf_task_def_arn" {
  description = "MobSF task definition ARN"
  value       = aws_ecs_task_definition.mobsf.arn
}
