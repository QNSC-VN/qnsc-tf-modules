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

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "config-file-type"  = "s3"
          "config-file-value" = "${module.config_bucket[0].arn}/${aws_s3_object.fluent_bit_config[0].key}"
        }
      }

      secrets = [
        { name = "OBSERVABILITY_TOKEN", valueFrom = var.token_secret_arn },
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

output "execution_s3_bucket_arns" {
  description = "Config bucket ARN the TASK EXECUTION role must be able to GetObject from. Pass into ecs-service's execution_s3_bucket_arns, or the router fails ResourceInitializationError the same way a missing secret would."
  value       = local.enabled ? [module.config_bucket[0].arn] : []
}

output "enabled" {
  value       = local.enabled
  description = "Whether the router is actually produced."
}
