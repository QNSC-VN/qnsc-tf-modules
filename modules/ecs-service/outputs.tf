output "service_name" {
  value       = aws_ecs_service.this.name
  description = "ECS service name."
}

output "service_arn" {
  value       = aws_ecs_service.this.id
  description = "ECS service ARN."
}

output "task_role_arn" {
  value       = aws_iam_role.task.arn
  description = "Task role ARN (runtime AWS access)."
}

output "execution_role_arn" {
  value       = aws_iam_role.execution.arn
  description = "Execution role ARN."
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "Task definition ARN."
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "CloudWatch log group name."
}

output "target_group_arn" {
  value       = var.attach_alb ? aws_lb_target_group.this[0].arn : null
  description = "ALB target group ARN (null when not ALB-attached)."
}
