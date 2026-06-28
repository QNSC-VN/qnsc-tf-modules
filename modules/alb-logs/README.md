# `alb-logs` module

S3 bucket (with the correct ELB delivery policy, public-access block, and a
retention lifecycle) for ALB access logs. Prod ALBs should log here for
incident / security / latency forensics.

## Usage

```hcl
module "alb_logs" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/alb-logs?ref=alb-logs-v1.0.0"

  bucket_name    = "myproduct-prod-alb-logs"
  retention_days = 90
  tags           = { Environment = "prod" }
}

resource "aws_lb" "this" {
  # ...
  access_logs {
    bucket  = module.alb_logs.bucket_id
    enabled = true
  }
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `bucket_name` | `string` | — | Globally-unique bucket name |
| `retention_days` | `number` | `90` | Days before logs expire |
| `force_destroy` | `bool` | `false` | Allow deletion of non-empty bucket |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
| :--- | :---------- |
| `bucket_id` | Bucket name (→ `aws_lb` access_logs.bucket) |
| `bucket_arn` | Bucket ARN |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
