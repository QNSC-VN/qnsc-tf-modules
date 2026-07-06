locals {
  # Custom domain is wired only when the domain, its zone, and the record name
  # are all provided — otherwise the SPA is reachable on <name>.pages.dev only.
  custom_domain_enabled = var.domain != "" && var.zone_id != "" && var.record_name != ""
}

# ── Pages project (direct-upload; content pushed by `wrangler pages deploy`) ──
resource "cloudflare_pages_project" "this" {
  account_id        = var.account_id
  name              = var.name
  production_branch = var.production_branch

  deployment_configs {
    production {
      environment_variables = var.production_env_vars
    }
  }
}

# ── Custom domain attached to the project ─────────────────────────────────────
resource "cloudflare_pages_domain" "this" {
  count = local.custom_domain_enabled ? 1 : 0

  account_id   = var.account_id
  project_name = cloudflare_pages_project.this.name
  domain       = var.domain
}

# ── DNS CNAME → <name>.pages.dev ──────────────────────────────────────────────
# Pages does NOT create the record for a custom domain, so we own it here.
# Proxied (orange-cloud) so it's served through Cloudflare's edge + TLS.
resource "cloudflare_record" "this" {
  count = local.custom_domain_enabled ? 1 : 0

  zone_id = var.zone_id
  name    = var.record_name
  type    = "CNAME"
  content = cloudflare_pages_project.this.subdomain
  proxied = true
  ttl     = 1
  comment = var.comment

  depends_on = [cloudflare_pages_domain.this]
}
