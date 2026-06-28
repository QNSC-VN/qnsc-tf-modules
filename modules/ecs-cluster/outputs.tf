output "cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "ARN of the ECS cluster."
}

output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "Name of the ECS cluster."
}
