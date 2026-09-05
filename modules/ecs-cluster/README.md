# `ecs-cluster` module

An ECS cluster with Fargate capacity providers (FARGATE + FARGATE_SPOT) and
CloudWatch Container Insights.

## Usage

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/quynhonsemiconductor/tf-modules.git//modules/ecs-cluster?ref=ecs-cluster-v1.0.0"

  name = "myproduct-develop"
  tags = local.tags

  # Optional overrides (defaults shown):
  # container_insights = "enhanced"   # "enabled" | "disabled"
  # fargate_base       = 1
  # fargate_weight     = 100
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | `string` | — | ECS cluster name |
| `container_insights` | `string` | `enhanced` | `enhanced` \| `enabled` \| `disabled` |
| `fargate_base` | `number` | `1` | Min tasks on FARGATE before weighting |
| `fargate_weight` | `number` | `100` | FARGATE weight in default strategy |
| `tags` | `map(string)` | `{}` | Tags applied to the cluster |

## Outputs

| Name | Description |
| :--- | :---------- |
| `cluster_arn` | ARN of the ECS cluster |
| `cluster_name` | Name of the ECS cluster |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
