output "ratelimit_ruleset_id" {
  value       = try(cloudflare_ruleset.ratelimit[0].id, null)
  description = "ID of the rate-limiting ruleset (null when no rules supplied)."
}

output "managed_ruleset_id" {
  value       = try(cloudflare_ruleset.managed[0].id, null)
  description = "ID of the managed-WAF ruleset (null when enable_managed_waf is false)."
}

output "custom_ruleset_id" {
  value       = try(cloudflare_ruleset.custom[0].id, null)
  description = "ID of the custom-firewall ruleset (null when no rules supplied)."
}
