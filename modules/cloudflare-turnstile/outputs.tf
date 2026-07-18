output "sitekey" {
  value       = cloudflare_turnstile_widget.this.id
  description = "Public Turnstile sitekey — safe to expose. Bake into the client (PUBLIC_TURNSTILE_SITEKEY / hardcode)."
}

output "secret" {
  value       = cloudflare_turnstile_widget.this.secret
  sensitive   = true
  description = "Turnstile secret — set out-of-band as the Pages TURNSTILE_SECRET env var. Never commit; never inject into app config from here."
}
