output "arn" {
  value       = aws_lb.this.arn
  description = "ALB ARN."
}

output "dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name (use as a CloudFront origin, or in health-check URLs)."
}

output "zone_id" {
  value       = aws_lb.this.zone_id
  description = "ALB hosted zone ID (for Route53/Cloudflare ALIAS records)."
}

output "https_listener_arn" {
  value       = aws_lb_listener.https.arn
  description = "HTTPS (:443) listener ARN — services attach forward rules here."
}

output "http_listener_arn" {
  value       = aws_lb_listener.http_redirect.arn
  description = "HTTP (:80) listener ARN — attach a /path rule here for CloudFront http-only origins."
}
