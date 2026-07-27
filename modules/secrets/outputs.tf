output "secret_arns" {
  value       = { for k, v in aws_secretsmanager_secret.app : k => v.arn }
  description = "Map of secret key → ARN (pass to ECS task definitions)."
}

output "secure_parameter_arns" {
  value       = { for k, v in aws_ssm_parameter.secure : k => v.arn }
  description = "Map of SecureString parameter key → ARN (pass to ECS task definitions as `secrets`)."
}

output "secure_parameter_names" {
  value       = { for k, v in aws_ssm_parameter.secure : k => v.name }
  description = "Map of SecureString parameter key → full name, for `aws ssm put-parameter`."
}

output "ssm_parameter_arns" {
  value       = { for k, v in aws_ssm_parameter.config : k => v.arn }
  description = "Map of SSM parameter key → ARN."
}
