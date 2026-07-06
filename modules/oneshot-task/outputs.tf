output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "Full task definition ARN (with revision)."
}

output "family" {
  value       = aws_ecs_task_definition.this.family
  description = "Task definition family — use with `aws ecs run-task --task-definition <family>`."
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "CloudWatch log group the task writes to."
}
