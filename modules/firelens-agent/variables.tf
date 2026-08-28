variable "name" {
  description = "Container name for the FireLens log router. Must be unique within the task definition."
  type        = string
  default     = "firelens-log-router"
}

variable "service_name" {
  description = <<-EOT
    OTel `service.name` to stamp on every log record this router forwards —
    must match the app's own hardcoded OTel service name (e.g. rally's
    `apps/api/src/app.module.ts` sets `serviceName: 'rally-api'`) so a
    service's metrics, traces AND logs land under the same `service_name` in
    Grafana. There is no SDK on this path to set it automatically the way
    observability-agent's `resource` processor backstops the app SDK — a
    log line is a raw stdout string with no OTel Resource attached, so this
    module must inject one via a Lua filter (see main.tf). Left unset, every
    log record's `service.name` was `unknown_service` (Grafana's fallback),
    making a service unfilterable in Loki even though the same service's
    metrics/traces filtered correctly.
  EOT
  type        = string
}

variable "product" {
  description = "Product slug. Becomes `service.namespace`, same convention and same value as observability-agent's `product` var — the two must agree, or a service's logs and its metrics/traces disagree about which namespace they belong to."
  type        = string
}

variable "env" {
  description = "Deployment environment as it should appear in telemetry (`develop`, `production`). Becomes `deployment.environment.name`, same convention and same value as observability-agent's `env` var. Deliberately NOT derived from NODE_ENV — see observability-agent's own variable for why."
  type        = string
}

variable "otlp_endpoint" {
  description = <<-EOT
    Upstream OTLP/HTTP base URL, e.g.
    `https://otlp-gateway-prod-ap-southeast-0.grafana.net/otlp`. The same value
    `observability-agent` uses for metrics/traces — one exporter protocol across
    all three signals.

    Empty disables the router entirely (`container_definitions` comes back
    empty), so a stack can adopt this module before a backend exists.
  EOT
  type        = string
  default     = ""
}

variable "token_secret_arn" {
  description = "Secrets Manager ARN holding the complete Authorization header value. Same secret observability-agent uses — same backend, same credential."
  type        = string
  default     = ""
}

variable "router_log_group" {
  description = "CloudWatch log group for the ROUTER's OWN stdout (diagnostics — is it running, is it erroring). Required, same reasoning as observability-agent: a silent router is indistinguishable from a working one. This is the ONLY place logs go through CloudWatch — app log content is Grafana-only, see main.tf's header comment for why."
  type        = string
}

variable "region" {
  description = "Region for the router's own awslogs driver."
  type        = string
}

variable "kms_key_arn" {
  description = "CMK ARN for SSE-KMS on the config bucket."
  type        = string
}

variable "image" {
  description = <<-EOT
    Fluent Bit image. Defaults to AWS's official, maintained distribution's
    `init` tag — required on Fargate (not just preferred): the plain
    `:stable` tag has no way to pull a custom config, since Fargate rejects
    FireLens' `config-file-type = "s3"` outright (EC2-launch-type only). The
    `init` variant runs a startup step that fetches S3-listed config files
    itself and `@INCLUDE`s them — see the module README.

    PINNED, deliberately, to a specific version — not `:init-latest`.
    `:init-latest` was tried first and resolved to Fluent Bit v1.9.10, whose
    `opentelemetry` output plugin has no `host`/`port`/`logs_uri`/`tls` at
    all ("unknown configuration property 'Logs_Uri'"), a pre-OTLP-maturity
    build despite the tag's name — found on a live develop task failure,
    not in testing. `init-3.4.14` is Fluent Bit v5.0.9 and was confirmed
    working by actually running the image against this module's rendered
    config (`docker run --entrypoint fluent-bit ... -o opentelemetry -h`,
    then a real startup test), not by reading documentation. Full list of
    available versions: `aws ssm get-parameters-by-path --path
    /aws/service/aws-for-fluent-bit/`.
  EOT
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:init-3.4.14"
}

variable "cpu" {
  type        = number
  default     = 128
  description = "Reserved CPU units. The router forwards; it does not process payloads."
}

variable "memory" {
  type        = number
  default     = 128
  description = "Hard memory limit in MiB."
}

variable "force_destroy_config_bucket" {
  description = "Allow destroying the config bucket with objects present. True by default: the config is regenerated from Terraform on every apply, never hand-authored, so nothing here is ever worth blocking a destroy over."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
