# =============================================================================
# firelens-agent — Fluent Bit log router sidecar (FireLens) for an ECS task.
#
# Produces a CONTAINER DEFINITION, not just a bucket, same shape as
# observability-agent:
#
#   module "firelens_agent" { source = ".../firelens-agent"  … }
#   module "api" {
#     source                   = ".../ecs-service"
#     additional_containers    = concat(module.otel_agent.container_definitions, module.firelens_agent.container_definitions)
#     secret_arns              = concat(local.secret_arns, module.firelens_agent.secret_arns)
#     execution_s3_bucket_arns = module.firelens_agent.execution_s3_bucket_arns
#     …
#   }
#   # And the app/worker containers' own logConfiguration switches from
#   # `awslogs` to `awsfirelens` — see the module README.
#
# DUAL-WRITE, not a swap: the generated Fluent Bit config fans every log line
# out to BOTH `cloudwatch_logs` (compliance retention, unchanged destination)
# AND `opentelemetry` (Grafana Cloud, the same backend observability-agent
# already sends metrics/traces to). ECS only allows one logDriver per
# container, so this — not keeping awslogs alongside awsfirelens on the app
# container, which is not possible — is how both destinations are satisfied
# at once.
#
# Why AWS's official image, not the community Grafana Loki Fluent Bit plugin:
# that plugin is no longer actively maintained (Grafana's own docs say so).
# `aws-for-fluent-bit` v3.0.0+ (Oct 2025) ships a native OpenTelemetry output
# plugin, so the router speaks the SAME protocol as observability-agent's
# otlphttp exporter — one exporter protocol across all three signals, no
# custom image build, no unmaintained dependency.
# =============================================================================

locals {
  enabled = var.otlp_endpoint != "" && var.token_secret_arn != ""

  # Fluent Bit's opentelemetry output takes Host/Port/URI separately, not one
  # endpoint URL — split what observability-agent's otlphttp exporter takes
  # as a single string. "/otlp" + "/v1/logs" is the same base-path convention
  # Grafana Cloud's gateway uses for traces ("/otlp" + "/v1/traces").
  otlp_host = local.enabled ? regex("^https?://([^/]+)", var.otlp_endpoint)[0] : ""
  otlp_path = local.enabled ? try(regex("^https?://[^/]+(/.*)$", var.otlp_endpoint)[0], "") : ""
  logs_uri  = "${local.otlp_path}/v1/logs"

  # ECS auto-generates [SERVICE]/[INPUT] ONLY when no custom config is
  # supplied. An external config file (config-file-type = "s3") REPLACES the
  # whole configuration, so both are written out explicitly here — the
  # `forward` input on the unix socket is the same one ECS's own generated
  # config always uses to receive from every container on this task whose
  # logDriver is `awsfirelens`.
  fluent_bit_config = <<-EOT
    [SERVICE]
        Flush     5
        Log_Level warn

    [INPUT]
        Name        forward
        unix_path   /var/run/fluent.sock

    [OUTPUT]
        Name              cloudwatch_logs
        Match             *
        region            ${var.region}
        log_group_name    ${var.cloudwatch_log_group}
        log_stream_prefix firelens-
        auto_create_group false

    [OUTPUT]
        Name          opentelemetry
        Match         *
        Host          ${local.otlp_host}
        Port          443
        Logs_Uri      ${local.logs_uri}
        Tls           On
        Tls.verify    On
        Header        Authorization $${OBSERVABILITY_TOKEN}
        Logs_Body_Key $$message
  EOT
}

module "config_bucket" {
  count  = local.enabled ? 1 : 0
  source = "../app-bucket"

  name          = "${var.name}-${substr(md5(var.cloudwatch_log_group), 0, 8)}-config"
  kms_key_arn   = var.kms_key_arn
  force_destroy = var.force_destroy_config_bucket
  tags          = var.tags
}

resource "aws_s3_object" "fluent_bit_config" {
  count        = local.enabled ? 1 : 0
  bucket       = module.config_bucket[0].bucket
  key          = "fluent-bit.conf"
  content      = local.fluent_bit_config
  content_type = "text/plain"
  etag         = md5(local.fluent_bit_config)
  tags         = var.tags
}
