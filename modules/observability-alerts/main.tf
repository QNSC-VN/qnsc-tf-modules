# =============================================================================
# observability-alerts — Grafana Alerting rule group for one product.
#
# ALONGSIDE CloudWatch Alarms, not replacing them: CloudWatch stays on
# infra-level signals (ECS task health, ALB target health) it can see
# directly. This module is for symptoms only the app's own OTel telemetry
# can see — DB pool contention, HTTP error rate, latency, job failure rate —
# the same data qnsc-infra/live/observability's stack already ingests.
#
# Uses a SECOND Grafana credential from observability-agent/firelens-agent's
# OTLP push token: alert-rule CRUD happens through the Grafana INSTANCE API
# (this module's `grafana_url`/`grafana_auth` provider config), not the
# Grafana Cloud ORG API the stack itself is managed through. See
# qnsc-infra/live/observability/main.tf's "Alerting" header comment.
#
# Each rule is the classic two-node Grafana Alerting pipeline — an instant
# Prometheus query (ref A) feeding a `__expr__` threshold node (ref B) — NOT
# a range query with client-side evaluation. Verified against real, working
# examples (compiler-explorer/infra and Grafana's own
# provisioning-alerting-examples repo) before writing this, the same
# discipline as every other "exact JSON/config shape" fix earlier in this
# module family: these APIs reject a near-miss shape with an unhelpful
# error, so this was checked against real working Terraform, not
# reconstructed from the resource schema alone.
# =============================================================================

terraform {
  required_version = ">= 1.9"
  required_providers {
    grafana = { source = "grafana/grafana", version = "~> 3.0" }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

resource "grafana_rule_group" "this" {
  name             = "${var.product} (${var.env})"
  folder_uid       = var.folder_uid
  interval_seconds = var.interval_seconds

  dynamic "rule" {
    for_each = { for r in var.rules : r.name => r }

    content {
      name      = rule.value.name
      condition = "B"
      for       = rule.value.for
      # A query returning no series (nothing scheduled, no traffic yet) is
      # not the same claim as "the threshold was crossed" — OK, not
      # Alerting, so an idle service does not page anyone.
      no_data_state = "OK"
      # A broken QUERY (bad PromQL, datasource down) is a real fault in the
      # alert pipeline itself, and staying silent about that is worse than
      # one spurious notification.
      exec_err_state = "Error"

      data {
        ref_id         = "A"
        query_type     = "instant"
        datasource_uid = var.prometheus_datasource_uid

        relative_time_range {
          from = 900 # 15m lookback — enough for rate()/histogram_quantile() windows up to 5m with margin
          to   = 0
        }

        model = jsonencode({
          refId      = "A"
          datasource = { type = "prometheus", uid = var.prometheus_datasource_uid }
          expr       = rule.value.promql
          instant    = true
          range      = false
          intervalMs = 1000
          # Grafana rejects a config with maxDataPoints unset or too low for
          # some panel types; this value is the provider ecosystem's common
          # default and has no cost implication for an instant query (one
          # point, not a series).
          maxDataPoints = 43200
        })
      }

      data {
        ref_id         = "B"
        datasource_uid = "__expr__"

        relative_time_range {
          from = 0
          to   = 0
        }

        model = jsonencode({
          refId      = "B"
          type       = "threshold"
          datasource = { type = "__expr__", uid = "__expr__" }
          expression = "A"
          conditions = [
            {
              evaluator = {
                type   = rule.value.op
                params = [rule.value.threshold]
              }
            }
          ]
          intervalMs    = 1000
          maxDataPoints = 43200
        })
      }

      labels = {
        product  = var.product
        env      = var.env
        severity = rule.value.severity
      }

      annotations = {
        summary = rule.value.summary
      }
    }
  }
}
