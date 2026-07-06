# =============================================================================
# alb — an application load balancer with the standard QNSC listener pair:
#   :443 HTTPS  → fixed-response 404 default (services attach their own rules)
#   :80  HTTP   → 301 redirect to HTTPS default
#
# Every product's ALB is byte-identical apart from deletion_protection (prod)
# and access_logs (prod). The LB + both listeners were hand-rolled in all four
# product env stacks before this. Services/rules attach to the exposed listener
# ARNs from the caller — the module owns the LB shape, not the routing (which
# is product/env-specific, e.g. dev's CloudFront /v1/* HTTP-forward quirk).
# =============================================================================

resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  # access_logs only when a bucket is provided (prod). Dynamic so dev omits it.
  dynamic "access_logs" {
    for_each = var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      enabled = true
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
