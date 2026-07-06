output "deploy_role_arns" {
  value       = { for k, v in aws_iam_role.deploy : k => v.arn }
  description = "Map of env → per-environment deploy role ARN."
}

output "ecr_push_role_arn" {
  value       = aws_iam_role.ecr_push.arn
  description = "ARN of the ECR push role."
}

output "infra_plan_role_arn" {
  value       = aws_iam_role.infra_plan.arn
  description = "ARN of the read-only infra plan role."
}

output "infra_apply_role_arn" {
  value       = aws_iam_role.infra_apply.arn
  description = "ARN of the infra apply role."
}

output "web_deploy_role_arns" {
  value       = { for k, v in aws_iam_role.web_deploy : k => v.arn }
  description = "Map of env → per-environment web (SPA) deploy role ARN."
}
