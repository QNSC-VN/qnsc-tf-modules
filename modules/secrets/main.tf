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

# Sensitive values in SSM Parameter Store as SecureString.
#
# Why here and not Secrets Manager: Secrets Manager bills $0.40 per container per
# month regardless of size, while STANDARD SSM parameters have no per-parameter
# charge at all. Ten app secrets across two environments is $8/mo of pure storage
# fee for ~2.4 KB of material. Both give KMS-CMK encryption at rest, both are
# readable by ECS `secrets` at container start, and both keep one ARN per value so
# IAM stays per-secret.
#
# Use `secret_names` (Secrets Manager) instead when a value needs rotation
# lambdas, cross-region replication, a resource policy, or exceeds the 4 KB
# standard-parameter limit. The RDS master credential is the canonical case — AWS
# owns and rotates it — and it is not created here at all.
#
# CREATED WITH A PLACEHOLDER, not empty: SSM rejects an empty value, so unlike a
# Secrets Manager container these cannot be created blank. `ignore_changes` then
# stops Terraform reverting the real value an operator sets out of band, and the
# parameter stays at VERSION 1 until someone does. That version number is the
# populated/unpopulated signal CI checks — metadata only, so the deploy role never
# needs to read a secret value. The placeholder is deliberately too short to pass
# the app's own minimum-length rules, so if it ever reaches a task the task fails
# to boot rather than running on a known-public string.
resource "aws_ssm_parameter" "secure" {
  for_each = var.secure_parameters

  name        = "/${var.prefix}/${each.key}"
  description = each.value
  type        = "SecureString"
  key_id      = var.kms_key_arn != "" ? var.kms_key_arn : null
  value       = "UNSET"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, { Name = "/${var.prefix}/${each.key}" })
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
