output "project_name" {
  value       = cloudflare_pages_project.this.name
  description = "Pages project name — pass to CI as the wrangler --project-name."
}

output "pages_dev_subdomain" {
  value       = cloudflare_pages_project.this.subdomain
  description = "Default <name>.pages.dev hostname the project is served on."
}

output "custom_domain" {
  value       = local.custom_domain_enabled ? var.domain : null
  description = "Custom domain the SPA is served on, or null when only pages.dev is used."
}
