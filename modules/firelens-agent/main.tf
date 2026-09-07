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
  # otlp_endpoint ALONE, deliberately — not "&& var.token_secret_arn != ''".
  # Every caller creates the secret under the same otlp_endpoint condition, so
  # the ARN is always eventually real; the difference is WHEN it is known.
  # On an environment's first-ever apply the secret doesn't exist yet, so its
  # ARN is unknown-until-apply, and `enabled` fed straight into config_bucket's
  # and fluent_bit_config's `count` — an unknown count is a hard error
  # ("Invalid count argument"), not a deferred plan. otlp_endpoint is a plain
  # string variable, always known at plan time, so this predicate can safely
  # gate a count on every apply, first or not.
  enabled = var.otlp_endpoint != ""

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
  #
  # The Lua FILTER below is not optional decoration — without it every log
  # record's OTel service.name is Grafana's fallback "unknown_service",
  # verified live: real develop logs landed in Loki queryable only as
  # {service_name="unknown_service"}, indistinguishable from every OTHER
  # unconfigured product's logs, while this same service's metrics/traces
  # correctly read service_name="rova-api" (set by the app's OTel SDK,
  # which has no equivalent hook on a raw-stdout log path). The plugin's
  # own `logs_resource_metadata_key` option (default "Resource") does
  # NOTHING in the pinned v5.0.9 build — read from the plugin's actual C
  # source (opentelemetry.c / opentelemetry_conf.c): it is declared but
  # never dereferenced. The real mechanism is a hardcoded record accessor,
  # `$resource['attributes']`, so the record must carry a top-level
  # lowercase `resource.attributes` map with dotted OTel keys — confirmed by
  # running this exact config against a local mock OTLP receiver and
  # inspecting the decoded payload before touching production.
  #
  # `code` (inline Lua source), not `script` (a file path): the FireLens
  # init process treats every S3 object listed via `aws_fluent_bit_init_s3_N`
  # as a Fluent Bit config fragment to `@INCLUDE` (or a parser file) with NO
  # third "plain asset" category (confirmed against the init process's own
  # Go source) — a `.lua` file shipped that way would be `@INCLUDE`d as
  # config and fail to parse. Inline `code` avoids needing a second S3
  # object entirely.
  #
  # `logs_body_key log`, not `$message`: FireLens' generated INPUT preserves
  # the Docker/ECS-agent forward-protocol record shape, which nests the
  # container's actual stdout line under a key literally named `log` —
  # confirmed by inspecting real records once they reached Loki, and by the
  # same local mock-receiver test above. `$message` never matched anything,
  # so every record's OTel log body was silently the ENTIRE raw envelope
  # (container_id, ecs_cluster, ecs_task_arn, ecs_task_definition, log —
  # all of it, JSON-serialized) instead of just the app's own line.
  resource_lua_code = "function add_resource(tag, ts, record) record[\"resource\"]={attributes={[\"service.name\"]=\"${var.service_name}\",[\"service.namespace\"]=\"${var.product}\",[\"deployment.environment.name\"]=\"${var.env}\"}} return 1, ts, record end"

  fluent_bit_config = <<-EOT
    [FILTER]
        Name    lua
        Match   *
        call    add_resource
        code    ${local.resource_lua_code}

    [OUTPUT]
        Name          opentelemetry
        Match         *
        host          ${local.otlp_host}
        port          443
        logs_uri      ${local.logs_uri}
        tls           On
        tls.verify    On
        header        Authorization $${OBSERVABILITY_TOKEN}
        logs_body_key log
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
