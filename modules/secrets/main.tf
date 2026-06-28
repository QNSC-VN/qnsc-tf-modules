# =============================================================================
# Secrets — Secrets Manager (app secrets) + SSM Parameter Store (config).
#
# Secrets are created EMPTY; actual values are set out-of-band (console, CI/CD,
# or aws-cli) and never committed to state. ECS task definitions reference them
# by ARN (see the `secret_arns` output).
# =============================================================================

resource "aws_secretsmanager_secret" "app" {
  for_each = var.secret_names

  name                    = "${var.prefix}/${each.key}"
  description             = each.value
  recovery_window_in_days = var.recovery_window_days
  kms_key_id              = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(var.tags, { Name = "${var.prefix}/${each.key}" })
}

# Non-sensitive configuration in SSM Parameter Store.
resource "aws_ssm_parameter" "config" {
  for_each = var.ssm_parameters

  name        = "/${var.prefix}/${each.key}"
  type        = "String"
  value       = each.value.value
  description = each.value.description

  tags = merge(var.tags, { Name = "/${var.prefix}/${each.key}" })
}
