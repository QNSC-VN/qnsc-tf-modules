# `waf` module

Regional WAFv2 WebACL for an ALB: AWS Managed Common Rules + Known Bad Inputs +
per-IP rate limiting, with CloudWatch logging and optional ALB association.

## Usage

```hcl
module "waf" {
  source = "git::https://github.com/quynhonsemiconductor/qnsc-tf-modules.git//modules/waf?ref=waf-v1.0.0"

  name    = "myproduct-prod"
  alb_arn = aws_lb.this.arn
  tags    = { Environment = "prod" }

  # rate_limit_per_5min = 2000   # requests/IP/5min before block
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | `string` | — | WebACL + metric/log name prefix |
| `enabled` | `bool` | `true` | Create the ACL (false = no WAF) |
| `alb_arn` | `string` | `""` | ALB to associate (empty = no association) |
| `rate_limit_per_5min` | `number` | `2000` | Per-IP rate-limit threshold |
| `log_retention_days` | `number` | `90` | WAF log retention |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
| :--- | :---------- |
| `web_acl_arn` | WebACL ARN (null when disabled) |
| `web_acl_id` | WebACL ID (null when disabled) |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
