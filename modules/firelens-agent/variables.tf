variable "name" {
  description = "Container name for the FireLens log router. Must be unique within the task definition."
  type        = string
  default     = "firelens-log-router"
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

variable "cloudwatch_log_group" {
  description = <<-EOT
    Destination CloudWatch Logs group for the DUAL-WRITE `cloudwatch_logs`
    output — normally the same log group the app container wrote to directly
    before adopting this module, so existing Insights queries and retention
    keep working unchanged. Compliance retention lives here; Grafana becomes
    the primary place engineers look.
  EOT
  type        = string
}

variable "router_log_group" {
  description = "CloudWatch log group for the ROUTER's OWN stdout (diagnostics — is it running, is it erroring). Required, same reasoning as observability-agent: a silent router is indistinguishable from a working one."
  type        = string
}

variable "region" {
  description = "Region for both the router's own awslogs driver and the cloudwatch_logs output."
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

    The one deliberately unpinned image reference in this org's modules:
    `init` tags don't track the same version numbers as `:stable`
    (`init-2.27.0` is a Fluent Bit version, not an aws-for-fluent-bit
    release), and AWS's own examples use `:init-latest` as the standard
    reference — pin to a specific `init-X.Y.Z` once one has been verified
    working, rather than guessing a version that may not exist.
  EOT
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:init-latest"
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
