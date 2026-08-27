output "container_definitions" {
  description = <<-EOT
    Router container definition(s), ready to pass straight to `ecs-service`'s
    `additional_containers`. An EMPTY list when `otlp_endpoint` or
    `token_secret_arn` is unset, so the module is a no-op until a backend
    exists — same gating as observability-agent.
  EOT
  value = local.enabled ? [
    {
      name      = var.name
      image     = var.image
      essential = true # every container routing logs through this one loses its log driver if it dies — a silent blackhole is worse than a task restart
      cpu       = var.cpu
      memory    = var.memory

      # No config-file-type/config-file-value: Fargate cannot fetch an
      # external FireLens config from S3 (EC2-launch-type only). The `:init-*`
      # image instead pulls it itself, via the env var below, and
      # `@INCLUDE`s it into the auto-generated config — ECS never sees a
      # custom config path.
      firelensConfiguration = {
        type = "fluentbit"
      }

      secrets = [
        { name = "OBSERVABILITY_TOKEN", valueFrom = var.token_secret_arn },
      ]

      environment = [
        {
          name  = "aws_fluent_bit_init_s3_1"
          value = "arn:aws:s3:::${module.config_bucket[0].bucket}/${aws_s3_object.fluent_bit_config[0].key}"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.router_log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.name
        }
      }
    }
  ] : []
}

output "secret_arns" {
  description = "Secret ARNs the TASK EXECUTION role must be able to read. Concat into ecs-service's secret_arns."
  value       = local.enabled ? [var.token_secret_arn] : []
}

output "task_s3_bucket_arns" {
  description = <<-EOT
    Config bucket ARN the TASK role must be able to GetObject from. Pass into
    ecs-service's EXISTING task-role-scoped `s3_bucket_arns` (NOT the
    execution role — AWS's own init-process docs are explicit: "IAM roles for
    tasks is different with ECS task execution role", because the init
    process runs inside the container at startup using the task's runtime
    credentials, not the boot-time execution role). Omitting this fails the
    same way a missing secret would, just later — the router starts, then the
    init step's S3 fetch gets AccessDenied.
  EOT
  value       = local.enabled ? [module.config_bucket[0].arn] : []
}

output "enabled" {
  value       = local.enabled
  description = "Whether the router is actually produced."
}
