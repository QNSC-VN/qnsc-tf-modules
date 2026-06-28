# `ecr` module

ECR container repositories with a lifecycle policy (expire untagged, cap tagged)
and an optional repository policy granting pull/push to specified principals.

## Usage

```hcl
module "ecr" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/ecr?ref=ecr-v1.0.0"

  repository_names = ["myproduct-api", "myproduct-worker"]
  kms_key_arn      = local.kms_key_arn      # omit for AES256
  tags             = local.tags

  # Optional overrides (defaults shown):
  # image_tag_mutability   = "IMMUTABLE"
  # keep_tagged_count      = 30
  # untagged_expire_days   = 1
  # tag_prefix_list        = ["sha-", "v"]
  # allowed_principal_arns = []   # set to create a repository policy
}
```

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `repository_names` | `list(string)` | — | Repositories to create |
| `image_tag_mutability` | `string` | `IMMUTABLE` | `IMMUTABLE` or `MUTABLE` |
| `kms_key_arn` | `string` | `""` | KMS key ARN (empty = AES256) |
| `keep_tagged_count` | `number` | `30` | Tagged images kept per repo |
| `untagged_expire_days` | `number` | `1` | Days before untagged images expire |
| `tag_prefix_list` | `list(string)` | `["sha-","v"]` | Prefixes the keep rule applies to |
| `allowed_principal_arns` | `list(string)` | `[]` | Principals for repo policy (empty = no policy) |
| `tags` | `map(string)` | `{}` | Tags applied to all repositories |

## Outputs

| Name | Description |
| :--- | :---------- |
| `repository_urls` | Map of repo name → URL |
| `repository_arns` | Map of repo name → ARN |

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
