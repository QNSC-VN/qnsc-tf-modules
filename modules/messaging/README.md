# `messaging` module

Data-driven SQS + SNS messaging. The caller supplies the topology (queues,
topics, subscriptions); the module provides the hardened primitives: a DLQ +
redrive policy per queue, SSE-encrypted queues, SNS-publish queue policies, and
KMS-encrypted topics.

## Usage

```hcl
module "messaging" {
  source = "git::https://github.com/quynhonsemiconductor/qnsc-tf-modules.git//modules/messaging?ref=messaging-v1.0.0"

  prefix = "myproduct-develop"

  queues = {
    notifications = {}
    audit         = { visibility_timeout = 60 }
    reporting     = { visibility_timeout = 300 }
  }

  topics = ["domain-events"]

  subscriptions = [
    {
      topic         = "domain-events"
      queue         = "notifications"
      filter_policy = jsonencode({ eventType = ["notification.created"] })
    }
  ]

  kms_key_arn = local.kms_key_arn
  tags        = local.tags
}
```

A simpler product (e.g. a single outbox queue) just supplies fewer entries:

```hcl
queues        = { outbox = { visibility_timeout = 60 } }
topics        = ["events"]
subscriptions = []
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `prefix` | `string` | — | Name prefix for queues/topics |
| `queues` | `map(object)` | `{}` | Queue short name → `{ visibility_timeout }`; each gets a DLQ |
| `topics` | `list(string)` | `[]` | SNS topic short names |
| `subscriptions` | `list(object)` | `[]` | `{ topic, queue, filter_policy }` SNS→SQS bindings |
| `create_queue_policies` | `bool` | `true` | Create SNS-publish queue policies |
| `dlq_max_receive_count` | `number` | `5` | Receives before moving to DLQ |
| `kms_key_arn` | `string` | `""` | KMS key for SNS (empty = AWS-managed) |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
| :--- | :---------- |
| `queue_urls` | Map of queue short name → URL |
| `queue_arns` | Map of queue short name → ARN |
| `dlq_arns` | Map of queue short name → DLQ ARN |
| `topic_arns` | Map of topic short name → ARN |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
