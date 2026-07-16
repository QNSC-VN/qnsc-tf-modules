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
