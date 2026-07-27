# =============================================================================
# observability-agent — OpenTelemetry Collector sidecar for an ECS task.
#
# Produces a CONTAINER DEFINITION, not infrastructure. The caller merges it into
# `ecs-service`'s existing `additional_containers`, so adopting this needs no
# change to the service module:
#
#   module "otel_agent" { source = ".../observability-agent"  … }
#   module "api" {
#     source                = ".../ecs-service"
#     additional_containers = module.otel_agent.container_definitions
#     secret_arns           = concat(local.secret_arns, module.otel_agent.secret_arns)
#     …
#   }
#
# Why a sidecar rather than one shared gateway: the app reaches it on
# `localhost:4318` through the task's shared network namespace, so there is no
# service discovery, no cross-AZ hop and no extra security group. The trade-off is
# that a sidecar only ever sees its own task's spans, which is why TAIL sampling
# (keep 100% of errors, sample the rest) is NOT possible here — a tail sampler must
# see every span of a trace. That needs a load-balancing gateway keyed by trace id,
# and is a deliberate later step. Until then head sampling in the SDK is the only
# lever, and a prod ratio below 1.0 loses most error traces.
#
# Everything is gated on `otlp_endpoint`: empty means no sidecar at all, so a stack
# can adopt this module and stay a no-op until a backend exists.
# =============================================================================

locals {
  enabled = var.otlp_endpoint != "" && var.token_secret_arn != ""

  # Collector configuration, passed inline via AOT_CONFIG_CONTENT rather than baked
  # into an image or fetched from S3/SSM — it keeps the config reviewable in the
  # same diff as the thing it configures.
  #
  # The Authorization header is read from the environment (`${env:...}`), never
  # interpolated by Terraform, so the credential stays out of the state file and out
  # of the task definition's plaintext `environment` block.
  config = yamlencode({
    receivers = {
      otlp = {
        protocols = {
          # Both protocols: the Node SDK exports over HTTP, but a future non-Node
          # workload in the same task may prefer gRPC. Bound to loopback because the
          # only legitimate clients share this task's network namespace.
          http = { endpoint = "127.0.0.1:4318" }
          grpc = { endpoint = "127.0.0.1:4317" }
        }
      }
    }

    processors = {
      # FIRST in every pipeline, deliberately. Under back-pressure the collector
      # must refuse new data while it drains; without this it grows until ECS
      # OOM-kills the container, which on a sidecar means the task restarts and the
      # APP goes down with it. Telemetry must never be able to do that.
      memory_limiter = {
        check_interval  = "1s"
        limit_mib       = var.memory_limit_mib
        spike_limit_mib = floor(var.memory_limit_mib * 0.25)
      }

      # Stamped here, not only in the SDK, so anything that ever exports through
      # this sidecar is attributed correctly even if it forgets.
      resource = {
        attributes = [
          { key = "deployment.environment.name", value = var.env, action = "upsert" },
          { key = "service.namespace", value = var.product, action = "upsert" },
        ]
      }

      # LAST before the exporter. Batching is what makes the egress cost sane; the
      # timeout bounds how long a span waits when traffic is thin.
      batch = {
        timeout         = "5s"
        send_batch_size = 512
      }
    }

    exporters = {
      otlphttp = {
        endpoint = var.otlp_endpoint
        headers  = { authorization = "$${env:OBSERVABILITY_TOKEN}" }
        # The app is not a queue. If the backend is unreachable, retry briefly then
        # DROP: an unbounded queue turns a telemetry outage into an application
        # memory leak.
        retry_on_failure = {
          enabled          = true
          initial_interval = "5s"
          max_interval     = "30s"
          max_elapsed_time = "120s"
        }
        sending_queue = { enabled = true, queue_size = 512 }
      }
    }

    service = merge(
      {
        pipelines = merge(
          {
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "resource", "batch"]
              exporters  = ["otlphttp"]
            }
          },
          var.metrics_enabled ? {
            metrics = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "resource", "batch"]
              exporters  = ["otlphttp"]
            }
          } : {}
        )
      },
      # No logs pipeline, on purpose: a sidecar cannot read another container's
      # stdout on ECS (that needs a FireLens log router), and app logs already go to
      # CloudWatch via the awslogs driver where the compliance retention lives.
      # `trace.id` is on every log line, so log↔trace correlation works without
      # moving logs at all.
      { telemetry = { logs = { level = var.log_level } } }
    )
  })
}
