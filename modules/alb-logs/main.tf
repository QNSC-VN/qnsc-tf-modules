# =============================================================================
# alb-logs — S3 bucket (with the correct delivery policy + lifecycle) for ALB
# access logs. Wire the bucket into an aws_lb access_logs block:
#
#   resource "aws_lb" "this" {
#     access_logs { bucket = module.alb_logs.bucket_id, enabled = true }
#   }
#
# ALB access logs are essential prod forensics: per-request client IP, latency,
# target, and response — for incident, security, and latency investigation.
# =============================================================================

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "logs" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = var.bucket_name })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    expiration { days = var.retention_days }
  }
}

# ALB log delivery requires the regional ELB service account to PutObject.
data "aws_iam_policy_document" "logs" {
  statement {
    sid       = "AllowELBLogDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }

  # Newer regions deliver via the log-delivery service principal instead.
  statement {
    sid       = "AllowLogDeliveryService"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}
