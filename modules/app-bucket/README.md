# app-bucket

A private, KMS-encrypted S3 bucket for application file storage (uploads,
attachments) with optional CORS (for browser presigned PUT) and lifecycle
rules. Consumed per product; the bucket name is injected into the app as an env
var (e.g. `S3_FILES_BUCKET` / `S3_ATTACHMENTS_BUCKET`).

> **Roadmap:** per COST_POSTURE_PLAN §11, file storage may migrate to
> Cloudflare R2 (zero-egress) for prod. This module stays the AWS-side option.

## Usage

```hcl
module "app_bucket" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/app-bucket?ref=app-bucket-v1.0.0"

  name          = "opshub-develop-uploads"
  kms_key_arn   = data.terraform_remote_state.bootstrap.outputs.kms_key_arn
  force_destroy = true # dev only
  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["https://opshub-dev.qnsc.vn"]
  }]
  tags = local.tags
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | string | — | Bucket name. |
| `kms_key_arn` | string | — | CMK ARN for SSE-KMS at rest. |
| `versioning` | bool | `false` | Enable object versioning. |
| `force_destroy` | bool | `false` | Allow destroy with objects present (dev). |
| `cors_rules` | list(object) | `[]` | CORS rules for browser presigned uploads. |
| `lifecycle_rules` | list(object) | `[]` | Expiration / noncurrent-version rules. |
| `tags` | map(string) | `{}` | Resource tags. |

## Outputs

| Name | Description |
| :--- | :---------- |
| `bucket` | Bucket name. |
| `arn` | Bucket ARN. |
| `bucket_regional_domain_name` | Regional domain name (for presigned URLs / origins). |
