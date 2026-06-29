output "web_acl_arn" {
  value       = var.enabled ? aws_wafv2_web_acl.this[0].arn : null
  description = "ARN of the WebACL (null when disabled)."
}

output "web_acl_id" {
  value       = var.enabled ? aws_wafv2_web_acl.this[0].id : null
  description = "ID of the WebACL (null when disabled)."
}
