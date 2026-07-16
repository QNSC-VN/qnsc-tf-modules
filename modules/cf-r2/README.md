# cf-r2

A Cloudflare **R2** (S3-compatible) object-storage bucket for application file
storage (uploads, attachments), with optional CORS (for browser presigned PUT)
and lifecycle rules. The R2-side counterpart to [`app-bucket`](../app-bucket)
(the AWS S3 module).

R2 has **zero egress fees**, so it is the cost-optimal home for attachment
storage (see `COST_POSTURE_PLAN` §11). The bucket name + S3 API endpoint are
injected into the app (`S3_ATTACHMENTS_BUCKET` / `STORAGE_ENDPOINT`) so the same
provider-agnostic `StorageService` (aws-sdk S3 client, `region="auto"`,
`forcePathStyle=true`) talks to R2 with no code change.

> **Provider major:** this module requires the Cloudflare provider **v5** (the
> R2 CORS / lifecycle resources exist only in v5). Because a root stack loads a
> single Cloudflare provider major, instantiate it from a v5 stack (the
> dedicated storage stack), **not** from a stack still pinned to the v4 provider.

## Usage

```hcl
module "attachments" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/cf-r2?ref=cf-r2-v1.0.0"

  account_id = data.terraform_remote_state.bootstrap.outputs.cloudflare_account_id
  name       = "rally-develop-attachments"
  location   = "apac" # co-locate with ap-southeast-1

  cors_rules = [{
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["https://rally-dev.qnsc.vn"]
    allowed_headers = ["*"]
  }]

  lifecycle_rules = [{
    id                              = "expire-tmp"
    prefix                          = "tmp/"
    expiration_days                 = 1
    abort_incomplete_multipart_days = 1
  }]
}
```

The consuming product stack reads `module.attachments.name` +
`module.attachments.endpoint` from this stack's remote state and sets them as
container env vars; the R2 access-key/secret live in AWS Secrets Manager. A
product stack therefore needs **no** Cloudflare provider to consume R2.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `account_id` | `string` | — | Cloudflare account ID that owns the bucket. |
| `name` | `string` | — | Bucket name (immutable; changing replaces the bucket). |
| `location` | `string` | `null` | Best-effort location hint: `apac`, `eeur`, `enam`, `weur`, `wnam`, `oc`. Honored only on first create. |
| `storage_class` | `string` | `"Standard"` | Default class for new objects: `Standard` or `InfrequentAccess`. |
| `jurisdiction` | `string` | `null` | Data residency: `default`, `eu`, `fedramp`. Changes the S3 endpoint host. |
| `cors_rules` | `list(object)` | `[]` | CORS rules for browser presigned uploads. |
| `lifecycle_rules` | `list(object)` | `[]` | Lifecycle rules (`expiration_days`, `abort_incomplete_multipart_days`). |

### `cors_rules[*]`

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `allowed_methods` | `list(string)` | — | e.g. `["PUT", "GET"]`. |
| `allowed_origins` | `list(string)` | — | Allowed origins. |
| `allowed_headers` | `list(string)` | `null` | Allowed request headers. |
| `expose_headers` | `list(string)` | `null` | Response headers exposed to the browser. |
| `max_age_seconds` | `number` | `null` | Preflight cache TTL. |
| `id` | `string` | `null` | Optional rule id. |

### `lifecycle_rules[*]`

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `string` | — | Rule id. |
| `prefix` | `string` | `""` | Object-key prefix the rule applies to. |
| `expiration_days` | `number` | `null` | Delete objects older than N days. |
| `abort_incomplete_multipart_days` | `number` | `null` | Abort multipart uploads not completed within N days. |

## Outputs

| Name | Description |
| --- | --- |
| `name` | Bucket name (inject as `S3_ATTACHMENTS_BUCKET`). |
| `id` | Bucket ID (equals the name). |
| `endpoint` | S3-compatible API endpoint (inject as `STORAGE_ENDPOINT`). |
