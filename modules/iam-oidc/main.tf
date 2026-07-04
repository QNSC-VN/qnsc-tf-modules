# =============================================================================
# iam-oidc — GitHub Actions OIDC deploy roles for a product.
#
# Creates the full role set every product needs (all scoped by var.product):
#   - <product>-github-deploy-<env>   per-environment app deploy (least privilege)
#   - <product>-github-ecr-push       image build/push (no env gate)
#   - <product>-github-infra-plan     read-only tofu plan on infra PRs
#   - <product>-github-infra-apply    tofu apply on infra main branch
#
# The GitHub OIDC provider itself is an account singleton owned by qnsc-infra;
# this module only consumes its ARN (never creates it).
# =============================================================================

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  ecr_arn    = "arn:aws:ecr:*:${local.account_id}:repository/${var.ecr_repository_pattern}"
  passrole   = "arn:aws:iam::${local.account_id}:role/${var.ecs_passrole_pattern}"
  infra_sub  = "repo:${var.github_org}/${var.infra_repo_name}"
}

# ── Per-environment app deploy roles ──────────────────────────────────────────
resource "aws_iam_role" "deploy" {
  for_each = var.environments

  name        = "${var.product}-github-deploy-${each.key}"
  description = "GitHub Actions deploy role for ${var.product} (${each.key})."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = each.value.allowed_subjects }
      }
    }]
  })

  tags = merge(var.tags, { Environment = each.key })
}

resource "aws_iam_role_policy" "deploy" {
  for_each = var.environments

  name = "${var.product}-deploy-${each.key}"
  role = aws_iam_role.deploy[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Sid = "ECRAuth", Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
          "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload", "ecr:DescribeRepositories", "ecr:ListImages",
        ]
        Resource = local.ecr_arn
      },
      {
        Sid    = "ECSDeploy"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition", "ecs:DescribeServices",
          "ecs:UpdateService", "ecs:RunTask", "ecs:DescribeTasks", "ecs:ListTaskDefinitions",
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRoleToECS"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = local.passrole
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      },
      { Sid = "Logs", Effect = "Allow", Action = ["logs:DescribeLogGroups"], Resource = "*" },
    ]
  })
}

# ── ECR push role (build jobs, no environment gate) ───────────────────────────
resource "aws_iam_role" "ecr_push" {
  name        = "${var.product}-github-ecr-push"
  description = "GitHub Actions image build/push role for ${var.product}."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            for repo in var.app_repo_names : "repo:${var.github_org}/${repo}:*"
          ]
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ecr_push" {
  name = "${var.product}-ecr-push"
  role = aws_iam_role.ecr_push.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
          "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload",
        ]
        Resource = local.ecr_arn
      },
    ]
  })
}

# ── Infra CI roles (the product's *-infra repo) ───────────────────────────────
# Read-only plan role for PRs.
resource "aws_iam_role" "infra_plan" {
  name        = "${var.product}-github-infra-plan"
  description = "GitHub Actions tofu plan (read-only) for ${var.infra_repo_name} PRs."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "${local.infra_sub}:*" }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "infra_plan_readonly" {
  role       = aws_iam_role.infra_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Apply role for main branch (broad; protected by branch rules + the sub condition).
resource "aws_iam_role" "infra_apply" {
  name        = "${var.product}-github-infra-apply"
  description = "GitHub Actions tofu apply for ${var.infra_repo_name} main branch."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Matches: ref:refs/heads/main, environment:shared, environment:develop, environment:production
          "token.actions.githubusercontent.com:sub" = "${local.infra_sub}:*"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "infra_apply_admin" {
  role       = aws_iam_role.infra_apply.name
  policy_arn = var.infra_apply_policy_arn
}
