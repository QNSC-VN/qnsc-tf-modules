# `cdn` module

S3 + CloudFront for hosting a single-page web app (SPA), with Origin Access
Control (OAC), HTTPS, and SPA-friendly error routing.

## Usage

```hcl
module "cdn" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/cdn?ref=cdn-v1.0.0"

  name         = "myproduct-web-develop"
  acm_cert_arn = var.web_acm_cert_arn      # MUST be in us-east-1
  aliases      = ["app-dev.myproduct.example.com"]
  price_class  = "PriceClass_200"
  tags         = local.tags
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | `string` | — | Unique name prefix for all resources |
| `acm_cert_arn` | `string` | — | ACM cert ARN — **must be created in us-east-1** (CloudFront requirement) |
| `aliases` | `list(string)` | `[]` | Custom domain aliases |
| `price_class` | `string` | `PriceClass_200` | `PriceClass_100` \| `PriceClass_200` \| `PriceClass_All` |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

See [`outputs.tf`](./outputs.tf).

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
