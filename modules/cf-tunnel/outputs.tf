output "id" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
  description = "Tunnel UUID."
}

output "cname" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.cname
  description = <<-EOT
    The CNAME target for a hostname served by this tunnel — "<id>.cfargotunnel.com".

    Read it from here rather than building the string: it is a Cloudflare-internal name
    that only resolves through the edge, so the DNS record MUST be proxied (orange
    cloud). An unproxied record cannot reach a connector.
  EOT
}

output "token" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive   = true
  description = "Connector token — the cloudflared sidecar's TUNNEL_TOKEN. A live credential."
}
