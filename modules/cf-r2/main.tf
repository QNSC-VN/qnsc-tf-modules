# =============================================================================
# cf-r2 — a Cloudflare R2 (S3-compatible) object-storage bucket for application
# file storage (user uploads / attachments). The R2-side counterpart to the AWS
# `app-bucket` module: consumed per product-per-env, its name + S3 endpoint are
# injected into the app (STORAGE_ENDPOINT / S3_ATTACHMENTS_BUCKET) so the same
# provider-agnostic StorageService (aws-sdk S3 client) talks to R2 unchanged.
#
# R2 has zero egress fees, so it is the cost-optimal home for attachment
# storage (see COST_POSTURE_PLAN §11). CORS is required for the browser
# presigned-PUT upload flow; lifecycle rules give the same tmp/-expiry +
# multipart-abort hygiene the S3 bucket had.
#
# Requires the Cloudflare provider v5 (the R2 CORS / lifecycle resources exist
# only in v5). Because a root stack loads a single Cloudflare provider major,
# instantiate this module from a v5 stack (e.g. the dedicated storage stack),
# not from a stack still pinned to the v4 provider.
# =============================================================================

resource "cloudflare_r2_bucket" "this" {
  account_id    = var.account_id
  name          = var.name
  location      = var.location
  storage_class = var.storage_class
  jurisdiction  = var.jurisdiction
}

# CORS — needed for browser presigned-PUT uploads (the SPA PUTs directly to R2).
resource "cloudflare_r2_bucket_cors" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this.id
  jurisdiction = var.jurisdiction

  rules = [for r in var.cors_rules : {
    id = r.id
    allowed = {
      methods = r.allowed_methods
      origins = r.allowed_origins
      headers = r.allowed_headers
    }
    expose_headers  = r.expose_headers
    max_age_seconds = r.max_age_seconds
  }]
}

# Lifecycle — expire transient objects (e.g. tmp/) and abort stale multipart
# uploads so incomplete uploads don't accrue storage cost. R2 lifecycle
# conditions are expressed in seconds; the module takes days and converts.
resource "cloudflare_r2_bucket_lifecycle" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this.id
  jurisdiction = var.jurisdiction

  rules = [for r in var.lifecycle_rules : {
    id         = r.id
    enabled    = true
    conditions = { prefix = r.prefix }

    delete_objects_transition = r.expiration_days == null ? null : {
      condition = {
        type    = "Age"
        max_age = r.expiration_days * 86400
      }
    }

    abort_multipart_uploads_transition = r.abort_incomplete_multipart_days == null ? null : {
      condition = {
        type    = "Age"
        max_age = r.abort_incomplete_multipart_days * 86400
      }
    }
  }]
}

# Custom domain — PUBLIC read access over a Cloudflare-proxied hostname, with
# edge caching. Gated on var.custom_domain being non-null so a private bucket
# can never acquire one by accident (see the variable's description).
resource "cloudflare_r2_custom_domain" "this" {
  count = var.custom_domain == null ? 0 : 1

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this.id
  domain       = var.custom_domain.hostname
  zone_id      = var.custom_domain.zone_id
  enabled      = true
  min_tls      = "1.2"
  jurisdiction = var.jurisdiction
}
