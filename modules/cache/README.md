# `cache` module

Valkey (Redis-compatible) on ElastiCache. Two modes:

| mode | What | Cost | Use |
| :--- | :--- | :--- | :-- |
| `serverless` (default) | ElastiCache Serverless, auto-scaling | ~$90/mo floor | prod |
| `node` | single `cache.t4g.micro`, encrypted in-transit + at-rest | ~$11/mo | dev |

> Serverless cannot be stopped (so the dev-scheduler can't help it). For real
> dev savings, use `mode = "node"`.

## Usage

```hcl
module "cache" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/cache?ref=cache-v1.0.0"

  name              = "myproduct-prod"
  subnet_ids        = module.network.data_subnet_ids
  security_group_id = module.network.sg_cache_id
  kms_key_arn       = local.kms_key_arn

  mode = "serverless"          # prod
  # mode = "node"              # dev (cheaper)

  max_data_storage_gb = 10
  max_ecpu_per_second = 10000
  tags                = { Environment = "prod" }
}
```

## Outputs

`endpoint`, `port`, `reader_endpoint` — work in both modes.

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
