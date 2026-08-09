output "secret_arns" {
  value = var.use_bundle ? {
    for k in keys(var.secret_names) : k => "${aws_secretsmanager_secret.bundle[0].arn}:${k}::"
  } : { for k, v in aws_secretsmanager_secret.app : k => v.arn }

  description = <<-EOT
    Map of secret key → an ECS `valueFrom` reference. Pass straight into a task
    definition's `secrets`.

    Standalone: a plain secret ARN. Bundled (`use_bundle`): "<bundle arn>:<key>::", the
    form ECS uses to read one key out of a JSON secret. Call sites are identical either
    way, which is the point — switching to a bundle is one input, not an edit at every
    reference.

    NOT usable as an IAM resource when bundled: the trailing ":<key>::" is a valueFrom
    suffix, not part of the ARN, and an IAM statement built from these silently matches
    nothing. Use `secret_iam_arns`.
  EOT
}

output "secret_iam_arns" {
  # NOT wrapped in distinct(), and that is load-bearing on a FIRST apply.
  #
  # These two lists are disjoint by construction — `create_standalone` and `use_bundle`
  # select which resources exist — so there is nothing to deduplicate. But distinct()
  # over values that do not exist yet returns a list of UNKNOWN LENGTH, because Terraform
  # cannot tell whether two unknown strings will turn out equal.
  #
  # That unknown length propagates into the consumer: ecs-service gates its execution
  # policy on `count = length(var.secret_arns) > 0`, and a count it cannot resolve fails
  # the plan outright with "The count value depends on resource attributes that cannot be
  # determined until apply". An existing environment plans fine because the ARNs are
  # already in state — so this only ever breaks the first apply of a new environment,
  # which is exactly when nobody has a working plan to compare against.
  value = concat(
    [for v in aws_secretsmanager_secret.app : v.arn],
    [for v in aws_secretsmanager_secret.bundle : v.arn],
  )

  description = <<-EOT
    Distinct ARNs of the secret CONTAINERS that exist, for the execution role's
    secretsmanager:GetSecretValue statement. One per standalone secret, or one for the
    whole bundle — IAM cannot scope below a secret, so a bundle is granted or it is not.

    Deliberately lists both while both exist (the retained-rollback step): granting a
    secret nothing references costs nothing, and it means reverting `use_bundle` is a
    one-line rollback rather than a rollback plus an IAM apply in the right order.
  EOT
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
