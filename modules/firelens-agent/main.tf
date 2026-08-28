# =============================================================================
# firelens-agent — Fluent Bit log router sidecar (FireLens) for an ECS task.
#
# Produces a CONTAINER DEFINITION, not just a bucket, same shape as
# observability-agent:
#
#   module "firelens_agent" { source = ".../firelens-agent"  … }
#   module "api" {
#     source                = ".../ecs-service"
#     additional_containers = concat(module.otel_agent.container_definitions, module.firelens_agent.container_definitions)
#     secret_arns            = concat(local.secret_arns, module.firelens_agent.secret_arns)
#     s3_bucket_arns          = module.firelens_agent.task_s3_bucket_arns
#     …
#   }
#   # And the app/worker containers' own logConfiguration switches from
#   # `awslogs` to `awsfirelens` — see the module README.
#
# GRAFANA ONLY, deliberately, not a CloudWatch dual-write. That was tried:
# FireLens' `cloudwatch_logs` output makes its own CloudWatch Logs API calls
# from inside the router container (unlike `awslogs`, whose writes are the
# ECS agent's own, via the execution role — no app-level IAM needed there).
# Granting the task role `logs:CreateLogStream`/`PutLogEvents` would have
# fixed it, but the org decided CloudWatch isn't worth keeping once Grafana
# already has the same data — no confirmed data-residency/compliance need
# for an AWS-native copy. If that changes, re-add the second `[OUTPUT]`
# block and the task-role grant together; don't do one without the other.
#
# Why AWS's official image, not the community Grafana Loki Fluent Bit plugin:
# that plugin is no longer actively maintained (Grafana's own docs say so).
# `aws-for-fluent-bit` ships a native OpenTelemetry output plugin (verified
# present and working at init-3.4.14, Fluent Bit v5.0.9 — see variables.tf
# for why the version must be pinned, not "latest"), so the router speaks
# the SAME protocol as observability-agent's otlphttp exporter — one
# exporter protocol across all three signals, no custom image build, no
# unmaintained dependency.
# =============================================================================

locals {
  enabled = var.otlp_endpoint != "" && var.token_secret_arn != ""

  # Fluent Bit's opentelemetry output takes host/port/uri separately, not one
  # endpoint URL — split what observability-agent's otlphttp exporter takes
  # as a single string. "/otlp" + "/v1/logs" is the same base-path convention
  # Grafana Cloud's gateway uses for traces ("/otlp" + "/v1/traces").
  otlp_host = local.enabled ? regex("^https?://([^/]+)", var.otlp_endpoint)[0] : ""
  otlp_path = local.enabled ? try(regex("^https?://[^/]+(/.*)$", var.otlp_endpoint)[0], "") : ""
  logs_uri  = "${local.otlp_path}/v1/logs"

  # OUTPUT blocks only. Fargate does not support FireLens' `config-file-type
  # = "s3"` at all (EC2-launch-type only — confirmed the hard way: ECS
  # rejects task registration with "Fargate launch type does not support
  # FirelensConfiguration config file from 's3'"). The fix is AWS's own
  # "init process" instead: the `:init-*` image tag runs a pre-launch step
  # that downloads each `aws_fluent_bit_init_s3_<N>` env var's S3 object and
  # `@INCLUDE`s it into the config ECS auto-generates — so [SERVICE] and
  # [INPUT] stay auto-managed, and only the OUTPUT stanzas below are ours.
  #
  # Field names are lowercase and verified by actually running this image
  # (`docker run --entrypoint fluent-bit ... -o opentelemetry -h`), not
  # assumed from docs: `init-latest` resolved to Fluent Bit v1.9.10, whose
  # opentelemetry output has NO host/port/logs_uri/tls at all ("unknown
  # configuration property 'Logs_Uri'") — an ancient, pre-OTLP-maturity
  # build, despite the tag's name. `init-3.4.14` (pinned in variables.tf) is
  # v5.0.9 and has the fields this config uses; confirmed by actually
  # starting the container against this exact config, not just parsing it.
  fluent_bit_config = <<-EOT
    [OUTPUT]
        Name          opentelemetry
        Match         *
        host          ${local.otlp_host}
        port          443
        logs_uri      ${local.logs_uri}
        tls           On
        tls.verify    On
        header        Authorization $${OBSERVABILITY_TOKEN}
        logs_body_key $message
  EOT
}

module "config_bucket" {
  count  = local.enabled ? 1 : 0
  source = "../app-bucket"

  name          = "${var.name}-${substr(md5(var.router_log_group), 0, 8)}-config"
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
