# firelens-agent

FireLens **log router** sidecar (Fluent Bit) for an ECS task. Emits a container
definition plus a small S3-hosted config; creates no other infrastructure.

Companion to `observability-agent`, not a replacement — that module ships
metrics/traces via direct OTLP push from the app SDK; this one exists only
because a sidecar cannot read another container's stdout on ECS. That needs a
FireLens log router, which is what this is.

App log content goes to Grafana only — CloudWatch was tried, worked, and was
removed on purpose. See "Grafana only" below.

## Usage

```hcl
module "firelens_agent" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/firelens-agent?ref=firelens-agent-v0.3.0"

  otlp_endpoint    = var.otlp_endpoint                              # "" ⇒ no-op, same gate as observability-agent
  token_secret_arn = module.secrets.secret_arns["observability-token"]
  router_log_group = module.api.log_group_name                      # router's OWN diagnostics only — see below
  region           = var.region
  kms_key_arn      = module.kms.key_arn
}

module "api" {
  source = "…//modules/ecs-service?ref=ecs-service-v2.3.1"

  additional_containers = concat(
    module.otel_agent.container_definitions,
    module.firelens_agent.container_definitions,
  )
  secret_arns = concat(
    local.app_secret_arns,
    module.otel_agent.secret_arns,
    module.firelens_agent.secret_arns,
  )
  # TASK role, not execution role — see "Why Fargate needs the init tag" below.
  s3_bucket_arns = module.firelens_agent.task_s3_bucket_arns

  # The app/worker containers' OWN logConfiguration switches from `awslogs`
  # to `awsfirelens` — ECS only allows one logDriver per container.
}
```

## Grafana only — CloudWatch was tried and dropped

The generated Fluent Bit config has ONE `[OUTPUT]` block: `opentelemetry`
(Grafana Cloud, same backend `observability-agent` already sends
metrics/traces to, same `Authorization` header secret). App log **content**
no longer reaches CloudWatch at all once this module is adopted —
`router_log_group` is only the router's own diagnostic stdout.

A `cloudwatch_logs` dual-write was built and verified working, then
deliberately removed: FireLens' `cloudwatch_logs` output makes its own
CloudWatch Logs API calls from inside the router container (unlike
`awslogs`, whose writes are the ECS agent's own, via the execution role —
no app-level IAM needed there), so it needed a task-role grant
(`logs:CreateLogStream`/`PutLogEvents`) that a plain `awslogs` setup never
did. With no confirmed data-residency/compliance need for a second,
AWS-native copy once Grafana already has the same data, keeping that grant
active for a destination nobody reads wasn't worth it. If that changes,
re-add the `[OUTPUT]` block and the task-role grant together — see git
history on this file for the exact shape.

**The app container's `logConfiguration` must change**, though — from
`awslogs` directly, to:

```hcl
logConfiguration = {
  logDriver = "awsfirelens"
  options   = {}
}
```

ECS allows exactly one log driver per container.

## Why AWS's official image, not the Grafana community Loki plugin

`grafana/fluent-bit-plugin-loki` is no longer actively maintained (Grafana's
own docs say so, and point at a "more feature-rich" official replacement).
`aws-for-fluent-bit` ships a **native OpenTelemetry output plugin** — the
router speaks the exact same protocol `observability-agent`'s `otlphttp`
exporter already does. One exporter protocol across metrics, traces, and
logs; no unmaintained dependency; no custom image build.

**The version matters, and "latest" lied about it.** `:init-latest`
resolved to Fluent Bit **v1.9.10**, whose `opentelemetry` output has no
`host`/`port`/`logs_uri`/`tls` — a pre-OTLP-maturity build, found only
because it crashed a real develop task ("unknown configuration property
'Logs_Uri'"). `init-3.4.14` (v5.0.9) has the fields this module's config
uses, verified by pulling the actual image and running
`fluent-bit -o opentelemetry -h` against it, then a real startup test —
not by reading AWS's release notes a second time. See `variables.tf`.

## Why Fargate needs the `init` tag, not `config-file-type = "s3"`

The obvious approach — FireLens' own `config-file-type = "s3"` — is
**EC2-launch-type only**. Fargate rejects it outright at task registration:

```
ClientException: Fargate launch type does not support FirelensConfiguration
config file from 's3'
```

(Found the hard way, on a real `tofu apply` against develop — not something
either AWS's FireLens docs or the plan output surfaced in advance.)

The fix is AWS's own **init process**, shipped in the `:init-*` image tags.
At container start, it downloads every `aws_fluent_bit_init_s3_<N>`
environment variable's S3 object and `@INCLUDE`s it into the Fluent Bit
config ECS auto-generates — so `[SERVICE]` and `[INPUT]` stay ECS-managed,
and this module's S3 object holds only the `[OUTPUT]` stanzas. No custom
image build either way.

**This is why `task_s3_bucket_arns`, not an execution-role grant.** The init
process runs inside the running container using the task's own runtime
credentials — AWS's docs state it plainly: *"IAM roles for tasks is
different with ECS task execution role."* The execution role (boot-time:
image pull, secrets/SSM injection) has nothing to do with this fetch.

## The token

Same secret `observability-agent` uses — the complete `Authorization` header
value, e.g. `Basic MTIzNDU2OmdsY19leUp...`. See that module's README for why
it is never assembled in Terraform.

## Deliberate choices

| Choice | Why |
|---|---|
| `essential = true` | Every container whose `logDriver` is `awsfirelens` loses its log driver entirely if this one dies. A task restart is safer than a silent, permanent log blackhole. |
| `port 443` hardcoded | Grafana Cloud's OTLP gateway is always HTTPS on 443; Fluent Bit's `opentelemetry` output takes host/port/uri separately, unlike `observability-agent`'s single-string `otlphttp` endpoint. |
| `image` pinned to `init-3.4.14`, not `:init-latest` | `:init-latest` silently resolved to an ancient, incompatible Fluent Bit build — see above. Bump deliberately, and re-verify (`docker run ... -o opentelemetry -h`) before trusting a newer tag's schema. |
| Config bucket, not SSM Parameter Store | The init process's `aws_fluent_bit_init_s3_<N>` mechanism only reads S3 objects; SSM is not an option here regardless of launch type. |
| `force_destroy_config_bucket = true` (default) | The config is regenerated by Terraform on every apply, never hand-authored — nothing in this bucket is ever worth blocking a destroy over. |

## Verification

Same discipline as `observability-agent`: apply to develop, then confirm
real log lines in Grafana Cloud Explore — CI green proves the container
started, not that logs arrived. Query Loki for
`{deployment_environment_name="develop"}` and expect real lines within
minutes of a deploy.
