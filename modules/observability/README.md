# observability

SNS-backed CloudWatch alarms + a dashboard for the golden signals of an
ECS-on-ALB-with-RDS service (ECS CPU/mem, ALB 5xx/latency, RDS
CPU/free-storage/connections). Cheap (~$0.10/mo alarms, ~$3/mo dashboard) and
additive — wire it from a product stack with handles it already has.

## Usage

```hcl
module "observability" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/observability?ref=observability-v4.0.0"

  name              = "rally-prod"
  region            = var.aws_region
  ecs_cluster_name  = module.ecs_cluster.cluster_name
  ecs_service_names = [module.api.service_name, module.worker.service_name]
  alb_arn           = data.terraform_remote_state.runtime.outputs.alb_arn
  rds_instance_id   = module.rds.identifier
  # Required for the two per-target-group alarms (latency, unhealthy hosts).
  target_group_arns = { api = module.api.target_group_arn }
  alarm_emails      = ["oncall@qnsc.vn"]
  tags              = local.tags
}
```

## Alarms

| Alarm | Scope | Notes |
| :---- | :---- | :---- |
| `<name>-<service>-cpu-high` / `-mem-high` | ECS service | Average over 2×5min. |
| `<name>-alb-5xx-high` | Load balancer | `HTTPCode_ELB_5XX_Count`. LB-wide on purpose — these are the ALB's own 5xx, not a target's. |
| `<name>-<tg>-alb-latency-high` | Target group | p95, **only evaluated in periods with ≥ `alb_latency_min_requests` requests**. |
| `<name>-<tg>-targets-unhealthy` | Target group | `treat_missing_data = "breaching"`. Disable via `monitor_target_health` where zero tasks is normal. |
| `<name>-rds-*` | RDS instance | CPU, free storage, connections. |

Both target-group alarms are scoped by `TargetGroup`, not `LoadBalancer`, because the
ALB is **shared across products** — a load-balancer-wide dimension aggregates every
product into one number and pages the wrong team.

The latency gate exists because a percentile over a handful of samples is not a
percentile. A pre-launch environment serving 0-6 requests per 5-minute period has a p95
equal to its second-slowest single request, so one slow call pages on-call for something
nobody can act on. Below the floor the expression returns 0 instead of the measured
value; above it the alarm behaves normally.

> **Breaking in v4.0.0:** `alb_latency` moved from one load-balancer-wide alarm
> (`<name>-alb-latency-high`, `count`) to one per target group
> (`<name>-<tg>-alb-latency-high`, `for_each`), and now requires `target_group_arns`.
> Callers that passed only `alb_arn` lose the latency alarm until they wire it.
> `monitor_target_health` no longer shares a switch with `target_group_arns`.

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | string | — | Prefix for alarm/dashboard names. |
| `region` | string | — | AWS region. |
| `ecs_cluster_name` | string | — | ECS cluster to alarm on. |
| `ecs_service_names` | list(string) | `[]` | Services to alarm on. |
| `alb_arn` | string | `""` | Full ALB ARN. Empty = skip ALB alarms. |
| `rds_instance_id` | string | `""` | RDS DBInstanceIdentifier. Empty = skip RDS alarms. |
| `target_group_arns` | map(string) | `{}` | Service name => target group ARN. Required for the latency and unhealthy-host alarms. |
| `monitor_target_health` | bool | `true` | Create the unhealthy-host alarm. False where zero running tasks is normal. |
| `alarm_emails` | list(string) | `[]` | Emails subscribed to the alarm topic. |
| `thresholds` | object | see module | Per-signal alarm thresholds (all optional, sane defaults). Includes `alb_latency_min_requests` (default 50). |
| `create_dashboard` | bool | `true` | Create the dashboard. Alarms are created regardless. |
| `tags` | map(string) | `{}` | Resource tags. |

## Outputs

| Name | Description |
| :--- | :---------- |
| `alarm_topic_arn` | SNS topic all alarms publish to — subscribe PagerDuty/Slack/email. |
| `dashboard_name` | CloudWatch dashboard name. |
