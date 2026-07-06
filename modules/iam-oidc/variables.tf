variable "product" {
  type        = string
  description = "Product name; prefixes every role (e.g. \"rally\" → rally-github-deploy-*)."
}

variable "github_org" {
  type        = string
  default     = "QNSC-VN"
  description = "GitHub org/owner that hosts the product repos."
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub OIDC provider (an account singleton from qnsc-infra)."
}

variable "environments" {
  type = map(object({
    allowed_subjects = list(string)
  }))
  description = <<-EOT
    Per-environment deploy roles. Key = env name (develop, production);
    allowed_subjects = the OIDC `sub` claims permitted to assume the role
    (e.g. "repo:ORG/myproduct-api:ref:refs/heads/main").
  EOT
}

variable "app_repo_names" {
  type        = list(string)
  description = "Repos allowed to assume the ecr-push role (e.g. [\"myproduct-api\"])."
}

variable "infra_repo_name" {
  type        = string
  description = "The product's infra repo name (e.g. \"myproduct-infra\")."
}

variable "ecr_repository_pattern" {
  type        = string
  description = "ECR repository name pattern these roles may push/pull (e.g. \"myproduct-*\")."
}

variable "ecs_passrole_pattern" {
  type        = string
  description = "IAM role name pattern the deploy role may PassRole to ECS (e.g. \"myproduct-*\" or \"myproduct-ecs-*\")."
}

variable "infra_apply_policy_arn" {
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
  description = "Managed policy attached to the infra-apply role. Start broad, tighten later."
}

variable "web_deploy_environments" {
  type = map(object({
    allowed_subjects = list(string)
    s3_bucket        = string
  }))
  default     = {}
  description = <<-EOT
    Per-environment web (SPA) deploy roles: S3 sync + CloudFront invalidation.
    Key = env name (develop/production); allowed_subjects = OIDC sub claims that
    may assume the role; s3_bucket = the env's web bucket name. Leave empty for
    products with no web frontend. Creates roles named
    "<product>-github-web-deploy-<env>" — the pattern every product hand-rolled
    before this was owned by the module.
  EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all roles."
}
