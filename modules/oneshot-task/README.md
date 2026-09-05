# oneshot-task

A standalone ECS/Fargate **task definition** (no service) for one-off runs —
database migrations, backfills, seeds — launched via `aws ecs run-task` (the CI
`run-db-migration` action wraps this). It only defines the task + its log group;
the caller runs it.

## Usage

```hcl
module "migrator" {
  source = "git::https://github.com/quynhonsemiconductor/tf-modules.git//modules/oneshot-task?ref=oneshot-task-v1.0.0"

  name               = "opshub-develop-migrator"
  container_name     = "migrator"
  image              = "${local.ecr}/opshub-migrator:latest"
  command            = ["node", "db/migrate.js"]
  execution_role_arn = module.ecs_cluster.execution_role_arn
  task_role_arn      = module.ecs_cluster.task_role_arn
  region             = var.aws_region
  secrets            = { DATABASE_URL = module.secrets.secret_arns["db-url"] }
  log_retention_days = 7
  tags               = local.tags
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | string | — | Task family + log group suffix. |
| `container_name` | string | `task` | Container name in the task def. |
| `image` | string | — | Container image URI. |
| `command` | list(string) | `[]` | Optional CMD override. Empty = image default. |
| `cpu` | number | `512` | Task CPU units. |
| `memory` | number | `1024` | Task memory (MiB). |
| `execution_role_arn` | string | — | Execution role (pull image, read secrets, write logs). |
| `task_role_arn` | string | — | Task role (runtime permissions). |
| `region` | string | — | Region for the awslogs driver. |
| `environment` | map(string) | `{}` | Plain env vars. |
| `secrets` | map(string) | `{}` | Secret env vars (name → Secrets Manager ARN). |
| `log_retention_days` | number | `7` | CloudWatch retention (90 in prod). |
| `tags` | map(string) | `{}` | Resource tags. |

## Outputs

| Name | Description |
| :--- | :---------- |
| `task_definition_arn` | Full task definition ARN (with revision). |
| `family` | Task family — use with `aws ecs run-task --task-definition <family>`. |
| `log_group_name` | CloudWatch log group the task writes to. |
