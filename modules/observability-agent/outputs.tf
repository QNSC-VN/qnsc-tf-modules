output "container_definitions" {
  description = <<-EOT
    Sidecar container definition(s), ready to pass straight to `ecs-service`'s
    `additional_containers`. An EMPTY list when `otlp_endpoint` or
    `token_secret_arn` is unset, so the module is a no-op until a backend exists.
  EOT
  value = local.enabled ? [
    {
      name      = var.name
      image     = var.image
      essential = false # telemetry must never take the app down with it
      cpu       = var.cpu
      memory    = var.memory

      # Inline config. AOT_CONFIG_CONTENT is how the AWS distribution accepts a
      # config without a mounted volume or a custom image.
      environment = [
        { name = "AOT_CONFIG_CONTENT", value = local.config },
      ]

      # The credential arrives as a secret, so it is never in the task definition's
      # plaintext. The collector config references it as ${env:OBSERVABILITY_TOKEN}.
      secrets = [
        { name = "OBSERVABILITY_TOKEN", valueFrom = var.token_secret_arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.name
        }
      }

      # No healthCheck, and not an omission: this image ships no shell and no
      # netcat, so any CMD-SHELL probe fails permanently and reports a healthy
      # collector as unhealthy. Verified directly against the image —
      #   exec: "sh": executable file not found in $PATH
      # `essential = false` already guarantees a collector failure cannot stop the
      # task, and the collector's own log (awslogs, below) is the real signal for
      # "running but not exporting", which a port probe could never detect anyway.
    }
  ] : []
}

output "secret_arns" {
  description = "Secret ARNs the TASK EXECUTION role must be able to read. Concat into `ecs-service`'s `secret_arns`, or the task fails to start with ResourceInitializationError."
  value       = local.enabled ? [var.token_secret_arn] : []
}

output "enabled" {
  description = "Whether the sidecar is actually produced. Useful for gating `OTEL_ENABLED` on the app container so the app never exports into a void."
  value       = local.enabled
}

output "endpoint" {
  description = "Value for the app's OTEL_EXPORTER_OTLP_ENDPOINT. Loopback, via the task's shared network namespace."
  value       = "http://127.0.0.1:4318"
}
