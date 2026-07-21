output "name" {
  value       = cloudflare_r2_bucket.this.name
  description = "R2 bucket name (inject as S3_ATTACHMENTS_BUCKET)."
}

output "id" {
  value       = cloudflare_r2_bucket.this.id
  description = "R2 bucket ID (equals the bucket name)."
}

output "endpoint" {
  value = format(
    "https://%s.%sr2.cloudflarestorage.com",
    var.account_id,
    (var.jurisdiction == null || var.jurisdiction == "default") ? "" : "${var.jurisdiction}."
  )
  description = <<-EOT
    S3-compatible API endpoint for this bucket (inject as STORAGE_ENDPOINT). The
    app's StorageService points its aws-sdk S3 client here with region "auto" and
    forcePathStyle=true. The host varies by jurisdiction.
  EOT
}

output "public_base_url" {
  value = try(
    "https://${cloudflare_r2_custom_domain.this[0].domain}",
    null,
  )
  description = <<-EOT
    Public HTTPS origin for this bucket, or null when no custom domain is
    attached. Inject as CDN_PUBLIC_ASSETS_BASE_URL — and ONLY ever from a bucket
    that is meant to be world-readable.
  EOT
}
