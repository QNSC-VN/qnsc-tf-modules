# observability

SNS-backed CloudWatch alarms + a dashboard for the golden signals of an
ECS-on-ALB-with-RDS service (ECS CPU/mem, ALB 5xx/latency, RDS
CPU/free-storage/connections). Cheap (~$0.10/mo alarms, ~$3/mo dashboard) and
additive — wire it from a product stack with handles it already has.

> **Status:** available (tagged `observability-v1.0.0`) but **not yet adopted**
> by any live stack. Wire it into product prod stacks when SLA monitoring is
> turned on (see COST_POSTURE_PLAN graduation triggers).

## Usage

```hcl
module "observability" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/observability?ref=observability-v1.0.0"

  name              = "rally-prod"
  region            = var.aws_region
  ecs_cluster_name  = module.ecs_cluster.cluster_name
  ecs_service_names = [module.api.service_name, module.worker.service_name]
  alb_arn           = data.terraform_remote_state.runtime.outputs.alb_arn
  rds_instance_id   = module.rds.instance_id
  alarm_emails      = ["oncall@qnsc.vn"]
  tags              = local.tags
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | string | — | Prefix for alarm/dashboard names. |
| `region` | string | — | AWS region. |
| `ecs_cluster_name` | string | — | ECS cluster to alarm on. |
| `ecs_service_names` | list(string) | `[]` | Services to alarm on. |
| `alb_arn` | string | `""` | Full ALB ARN. Empty = skip ALB alarms. |
| `rds_instance_id` | string | `""` | RDS DBInstanceIdentifier. Empty = skip RDS alarms. |
| `alarm_emails` | list(string) | `[]` | Emails subscribed to the alarm topic. |
| `thresholds` | object | see module | Per-signal alarm thresholds (all optional, sane defaults). |
| `tags` | map(string) | `{}` | Resource tags. |

## Outputs

| Name | Description |
| :--- | :---------- |
| `alarm_topic_arn` | SNS topic all alarms publish to — subscribe PagerDuty/Slack/email. |
| `dashboard_name` | CloudWatch dashboard name. |
