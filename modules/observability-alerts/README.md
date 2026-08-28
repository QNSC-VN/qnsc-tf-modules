# observability-alerts

Grafana Alerting rule group for one product. Creates no dashboards, no
datasources, no contact points — those are provisioned once, centrally, in
`qnsc-infra/live/observability`. This module only turns a list of
`{promql, threshold}` pairs into `grafana_rule_group` rules.

## Alongside CloudWatch Alarms, not replacing them

CloudWatch stays on infra-level signals it can see directly (ECS task
health, ALB target health). This module is for symptoms only the app's own
OTel telemetry can see — DB pool contention, HTTP error rate, latency, job
failure rate. Don't duplicate a CloudWatch Alarm here; don't try to make
CloudWatch alert on something only Grafana has data for.

## Usage

```hcl
module "alerts" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/observability-alerts?ref=observability-alerts-v0.1.0"

  product                   = "rally"
  env                       = var.env
  grafana_url               = var.grafana_alerting.url
  grafana_auth              = var.grafana_alerting.auth        # CI secret, e.g. GRAFANA_ALERTS_TOKEN — see below
  prometheus_datasource_name = var.grafana_alerting.prometheus_datasource_name
  folder_uid                = var.grafana_alerting.folder_uid

  rules = [
    {
      name      = "db-pool-contention"
      promql    = "db_pool_waiting{deployment_environment_name=\"${var.env}\"}"
      for       = "5m"
      op        = "gt"
      threshold = 0
      severity  = "warning"
      summary   = "Connections are queueing for the DB pool in ${var.env} — pool is undersized or a query is holding connections too long."
    },
  ]
}
```

## Why a second credential, not the OTLP push token

`observability-agent`/`firelens-agent`'s token is scoped `metrics:write
logs:write traces:write` — write-only, deliberately, and lives inside every
running ECS task. Alert-rule CRUD happens through the Grafana INSTANCE API
(the Grafana UI's own backend), a completely different surface from the
OTLP ingest gateway those tokens authenticate to. A stack-scoped SERVICE
ACCOUNT token is what that surface needs — provisioned once in
`qnsc-infra/live/observability` (`grafana_cloud_stack_service_account`),
never inside a product's task definition.

**This token reaches a product's CI as a plain GitHub Actions secret, NOT
through AWS Secrets Manager.** The OTLP token needs to be dereferenced at
APP RUNTIME (inside a running ECS task), so Secrets Manager is the right
place for it. This token is needed at TERRAFORM PLAN/APPLY time only —
nothing running in a task ever calls the Grafana instance API — so putting
it in Secrets Manager would just be a second, unnecessary place a leaked
task credential could reach it from.

## `prometheus_datasource_name`, not a UID

This module resolves the Mimir datasource's UID itself (`data
"grafana_data_source"`, in main.tf), from a NAME passed in. It does not take
the UID directly. Found the hard way: qnsc-infra/live/observability
originally did that lookup centrally and passed the UID down — which broke
`tofu plan` on a fresh apply with `Error: the Grafana client is required
for this resource`, because a `data` source (unlike a resource) can't defer
its read to apply time, and the service account token that read would
authenticate with does not exist yet in the SAME plan that creates it. This
module never hits that: `grafana_url`/`grafana_auth` here are always plain,
already-known CI-secret values by the time any product applies, never a
same-run resource attribute — no bootstrap ordering problem to have.

## Query shape — why instant + threshold, not a range query

Every rule is the classic two-node Grafana Alerting pipeline: an instant
Prometheus query (`ref A`) feeding a `__expr__` threshold expression node
(`ref B`), `condition = "B"`. This is NOT reconstructed from the Terraform
provider's resource schema alone — the exact JSON shape for `data[].model`
is undocumented in the schema itself (it's an opaque `jsonencode`d blob) and
a near-miss shape is rejected by Grafana's API with an unhelpful error, the
same class of problem as `firelens-agent`'s Fluent Bit config. Verified
against two independent real, working examples before writing this:
`compiler-explorer/infra`'s `alerts_ce.tf` and Grafana's own
`provisioning-alerting-examples` repo.

## Deliberate choices

| Choice | Why |
|---|---|
| `promql` used verbatim, no label injection | String surgery on arbitrary PromQL to inject a label filter is exactly the kind of hidden magic that silently breaks on a query shape nobody tested. Write the environment/product filter into the query yourself. |
| `no_data_state = "OK"` | A query returning no series (nothing scheduled yet, no traffic) is not the same claim as "the threshold was crossed." An idle service should not page anyone. |
| `exec_err_state = "Error"` | A broken query (bad PromQL, datasource down) is a real fault in the alerting pipeline itself — staying silent about that is worse than one spurious notification. |
| `op` values (`gt`/`lt`/`ge`/`le`/`eq`/`ne`), not `>`/`<` | Grafana's threshold evaluator type strings, not comparison operators — the API rejects the latter. |
| One `grafana_rule_group` per product/env, not per rule | Rules in the same group share one evaluation interval and one folder — matches how they're read together in the UI, and avoids a resource per alert. |
