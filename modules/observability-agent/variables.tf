variable "name" {
  description = "Container name for the sidecar. Must be unique within the task definition."
  type        = string
  default     = "otel-agent"
}

variable "product" {
  description = "Product slug. Becomes `service.namespace`, which is how signals are attributed and cost-split per product inside a shared backend."
  type        = string
}

variable "env" {
  description = <<-EOT
    Deployment environment as it should appear in telemetry (`develop`,
    `production`). Becomes `deployment.environment.name`.

    Deliberately NOT derived from NODE_ENV: products pin NODE_ENV to "production"
    outside production (rally's develop does, so a public host cannot expose
    passwordless dev-login), which would label every develop signal as production.
  EOT
  type        = string
}

variable "otlp_endpoint" {
  description = <<-EOT
    Upstream OTLP/HTTP base URL, e.g.
    `https://otlp-gateway-prod-ap-southeast-1.grafana.net/otlp`.

    Empty disables the sidecar entirely (`container_definitions` comes back empty),
    so a stack can adopt this module before a telemetry backend exists.
  EOT
  type        = string
  default     = ""
}

variable "token_secret_arn" {
  description = <<-EOT
    Secrets Manager ARN holding the COMPLETE Authorization header value, e.g.
    `Basic MTIzNDU2OmdsY19 leyJ...`.

    The whole header, not just the token: Grafana Cloud wants
    `Basic base64(instanceID:token)`, and assembling that in Terraform would put the
    instance id in state and the config in plaintext. One opaque secret keeps the
    credential out of both.
  EOT
  type        = string
  default     = ""
}

variable "image" {
  description = <<-EOT
    Collector image. Defaults to the AWS distribution of the OpenTelemetry
    Collector, which is on ECR Public — no Docker Hub rate limit on the pull path,
    unlike `otel/opentelemetry-collector-contrib`.
  EOT
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-otel-collector:v0.43.3"
}

variable "cpu" {
  description = "Reserved CPU units. The sidecar batches and forwards; it does not process payloads."
  type        = number
  default     = 128
}

variable "memory" {
  description = "Hard memory limit in MiB. Must exceed `memory_limit_mib` below, or memory_limiter can never shed load before the container is OOM-killed."
  type        = number
  default     = 256
}

variable "memory_limit_mib" {
  description = "Soft limit at which memory_limiter starts refusing data. Kept well under `memory` so the collector degrades by dropping telemetry rather than by dying and taking the task with it."
  type        = number
  default     = 160
}

variable "log_group" {
  description = "CloudWatch log group for the sidecar's own logs. Required — a silent collector is indistinguishable from a working one."
  type        = string
}

variable "region" {
  description = "Region for the awslogs driver."
  type        = string
}

variable "log_level" {
  description = "Collector's own log level. `warn` keeps a healthy collector quiet; raise to `info` when diagnosing why nothing arrives."
  type        = string
  default     = "warn"
}

variable "metrics_enabled" {
  description = "Forward the metrics pipeline. Traces are usually adopted first, and a metrics pipeline with no metrics is harmless but noisy in the collector log."
  type        = bool
  default     = true
}
