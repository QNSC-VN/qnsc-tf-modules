# `secrets` module

Creates **empty** AWS Secrets Manager secrets (values set out-of-band) plus
optional SSM Parameter Store entries for non-sensitive config.

## Usage

```hcl
module "secrets" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/secrets?ref=secrets-v1.0.0"

  prefix      = "myproduct/develop"
  kms_key_arn = local.kms_key_arn

  secret_names = {
    "db-url"      = "PostgreSQL connection URL"
    "jwt-private" = "EC P-256 (ES256) private key (PEM, base64)"
    "jwt-public"  = "EC P-256 (ES256) public key (PEM, base64)"
  }

  # Optional non-sensitive config:
  # ssm_parameters = {
  #   "feature-flag" = { value = "on", description = "…" }
  # }

  tags = local.tags
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `prefix` | `string` | — | Namespace prefix (`<prefix>/<key>`) |
| `secret_names` | `map(string)` | — | Secret key → description; one empty secret each |
| `ssm_parameters` | `map(object)` | `{}` | key → `{ value, description }` |
| `kms_key_arn` | `string` | `""` | KMS key for encryption (empty = AWS-managed key) |
| `recovery_window_days` | `number` | `7` | Days before permanent delete (0 = immediate) |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
| :--- | :---------- |
| `secret_arns` | Map of secret key → ARN |
| `ssm_parameter_arns` | Map of SSM parameter key → ARN |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
