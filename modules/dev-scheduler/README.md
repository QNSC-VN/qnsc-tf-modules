# `dev-scheduler` module

Stops dev resources off-hours to cut cost. A tag-driven Lambda, invoked by two
EventBridge schedules (stop in the evening, start in the morning, weekdays):

- **RDS** tagged `AutoStop=true` → stopped / started (Multi-AZ skipped — AWS
  can't stop those, so safe to leave on prod).
- **ECS services** tagged `AutoStop=true` → `desiredCount` set to 0, then
  restored to the pre-stop count (stashed in a tag).

Typical saving: **~50-65%** of a dev environment's compute + DB cost. Use only
in **develop** — never tag prod resources `AutoStop=true`.

> ElastiCache Serverless cannot be stopped (only deleted), so it is **not**
> covered here. For cache cost in dev, use a small node instead of serverless.

## Usage

```hcl
# In live/develop only:
module "dev_scheduler" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/dev-scheduler?ref=dev-scheduler-v1.0.0"

  name = "myproduct-develop"
  tags = { Environment = "develop" }

  # Defaults: stop 20:00, start 08:00, Mon-Fri, Asia/Ho_Chi_Minh
  # stop_cron  = "cron(0 20 ? * MON-FRI *)"
  # start_cron = "cron(0 8 ? * MON-FRI *)"
}
```

Then tag the resources to control. On the RDS and ECS modules, add to `tags`:

```hcl
tags = { Environment = "develop", AutoStop = "true" }
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | `string` | — | Resource name prefix |
| `tag_key` | `string` | `AutoStop` | Tag key opting a resource in |
| `tag_value` | `string` | `true` | Required tag value |
| `stop_cron` | `string` | `cron(0 20 ? * MON-FRI *)` | When to stop |
| `start_cron` | `string` | `cron(0 8 ? * MON-FRI *)` | When to start |
| `timezone` | `string` | `Asia/Ho_Chi_Minh` | IANA tz for the crons |
| `tags` | `map(string)` | `{}` | Tags on scheduler resources |

## Outputs

| Name | Description |
| :--- | :---------- |
| `lambda_function_arn` | Scheduler Lambda ARN |
| `lambda_function_name` | Scheduler Lambda name (manual invoke / logs) |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`, archive provider `>= 2.4`
- Python 3.13 Lambda runtime
