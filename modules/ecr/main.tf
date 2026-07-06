# =============================================================================
# ECR — container repositories with lifecycle + optional pull/push policy.
# =============================================================================

resource "aws_ecr_repository" "repos" {
  for_each             = toset(var.repository_names)
  name                 = each.key
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete # allow teardown even with images present

  encryption_configuration {
    # KMS when a key is provided, otherwise AES256 (AWS-managed).
    encryption_type = var.kms_key_arn != "" ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn != "" ? var.kms_key_arn : null
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, { Name = each.key })
}

# Lifecycle: expire untagged images, then cap the number of tagged images kept.
resource "aws_ecr_lifecycle_policy" "repos" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after ${var.untagged_expire_days} day(s)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expire_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.keep_tagged_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.tag_prefix_list
          countType     = "imageCountMoreThan"
          countNumber   = var.keep_tagged_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

# Repository policy — only created when principals are supplied.
resource "aws_ecr_repository_policy" "repos" {
  for_each   = length(var.allowed_principal_arns) > 0 ? aws_ecr_repository.repos : {}
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowDeployRoles"
        Effect    = "Allow"
        Principal = { AWS = var.allowed_principal_arns }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
      }
    ]
  })
}
