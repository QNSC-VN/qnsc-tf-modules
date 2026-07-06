# =============================================================================
# product-stack — one composition module that wires a product's full per-env
# infrastructure from the building-block modules. Collapses the ~300-line, near-
# identical live/develop + live/prod main.tf into a single module block + values.
#
# Philosophy: covers the standard 90% chain and EXPORTS rich handles (vpc/subnet/
# sg ids, ALB listener ARNs, ECS role ARNs, cdn domain) so a product can still
# bolt on its few quirks in the stack alongside this module — no need to model
# every product's edge case in the interface.
# =============================================================================

variable "product" { type = string }
variable "env" { type = string } # develop | prod
variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "azs" { type = list(string) }

variable "kms_key_arn" { type = string }

# ── Networking ───────────────────────────────────────────────────────────────
variable "network" {
  type = object({
    vpc_cidr                   = string
    public_subnet_cidrs        = list(string)
    private_subnet_cidrs       = list(string)
    data_subnet_cidrs          = list(string)
    app_port                   = optional(number, 3000)
    nat_type                   = optional(string, "instance")
    multi_az_nat               = optional(bool, false)
    enable_flow_logs           = optional(bool, false)
    flow_log_retention_days    = optional(number, 90)
    enable_interface_endpoints = optional(bool, false)
    # Lock ALB ingress to these CIDRs (Cloudflare IPs). Empty = 0.0.0.0/0.
    alb_ingress_cidrs = optional(list(string), [])
  })
}

# ── Secrets (created empty; values set out-of-band) ──────────────────────────
variable "secret_names" {
  type    = map(string)
  default = {}
}
variable "secrets_recovery_window_days" {
  type    = number
  default = 30
}

# ── RDS ──────────────────────────────────────────────────────────────────────
variable "rds" {
  type = object({
    instance_class           = string
    allocated_storage_gb     = optional(number, 20)
    max_allocated_storage_gb = optional(number, 100)
    multi_az                 = optional(bool, false)
    deletion_protection      = optional(bool, true)
    backup_retention_days    = optional(number, 7)
    monitoring_interval      = optional(number, 0)
  })
}

# ── Cache ──────────────────────────────────────────────────────────────────
variable "cache" {
  type = object({
    mode = optional(string, "node")
  })
  default = { mode = "node" }
}

# ── Messaging ────────────────────────────────────────────────────────────────
variable "messaging" {
  type = object({
    queues        = optional(map(any), {})
    topics        = optional(list(string), [])
    subscriptions = optional(list(any), [])
    kms_key_arn   = optional(string) # defaults to the stack CMK when null
  })
  default = {}
}

# ── ALB ──────────────────────────────────────────────────────────────────────
variable "alb" {
  type = object({
    certificate_arn            = string
    enable_deletion_protection = optional(bool, false)
    access_logs_bucket         = optional(string)
  })
}

# ── ECS services (api, worker, …) ────────────────────────────────────────────
variable "services" {
  type = map(object({
    image_uri          = string
    cpu                = number
    memory             = number
    desired_count      = optional(number, 1)
    min_count          = optional(number, 1)
    max_count          = optional(number, 3)
    use_spot           = optional(bool, false)
    log_retention_days = optional(number, 30)
    # ALB attach (api only, typically). Null = no ALB (worker).
    attach_alb        = optional(bool, false)
    alb_priority      = optional(number, 100)
    alb_path_patterns = optional(list(string), ["/*"])
    health_check_path = optional(string, "/v1/healthz")
    environment_vars  = optional(list(object({ name = string, value = string })), [])
    secrets           = optional(list(object({ name = string, secret_arn = string })), [])
    autostop          = optional(bool, false)
  }))
}

# ── Migrator (one-shot task; reuses a service's IAM roles) ───────────────────
variable "migrator" {
  type = object({
    enabled            = bool
    image_uri          = string
    cpu                = optional(number, 512)
    memory             = optional(number, 1024)
    log_retention_days = optional(number, 30)
    roles_from_service = optional(string, "api") # which service's exec/task roles to reuse
  })
  default = { enabled = false, image_uri = "" }
}

# ── App buckets (uploads / attachments) ──────────────────────────────────────
variable "app_buckets" {
  type = map(object({
    versioning    = optional(bool, false)
    force_destroy = optional(bool, false)
    cors_rules = optional(list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string), [])
      max_age_seconds = optional(number, 3600)
    })), [])
    lifecycle_rules = optional(list(object({
      id              = string
      prefix          = optional(string, "")
      expiration_days = optional(number)
      noncurrent_days = optional(number)
    })), [])
  }))
  default = {}
}

# ── WAF (regional, ALB) ──────────────────────────────────────────────────────
variable "waf" {
  type = object({
    enabled             = optional(bool, false)
    rate_limit_per_5min = optional(number, 2000)
    log_retention_days  = optional(number, 90)
  })
  default = { enabled = false }
}

# ── CDN (web SPA) ────────────────────────────────────────────────────────────
variable "cdn" {
  type = object({
    enabled                = optional(bool, true)
    bucket_name            = string
    aliases                = optional(list(string), [])
    acm_cert_arn           = optional(string) # us-east-1
    price_class            = optional(string, "PriceClass_100")
    api_origin_domain_name = optional(string) # set → CloudFront /v1 proxy (opshub-style edge)
    web_acl_arn            = optional(string) # CLOUDFRONT-scoped WAF
    force_destroy          = optional(bool, false)
  })
}

# ── DNS records (Cloudflare) ─────────────────────────────────────────────────
variable "dns_records" {
  type = map(object({
    name    = string
    type    = optional(string, "CNAME")
    content = string
    proxied = optional(bool, false)
    comment = optional(string, "")
  }))
  default = {}
}
variable "cloudflare_zone_id" {
  type    = string
  default = ""
}

# ── Dev cost-saver scheduler ─────────────────────────────────────────────────
variable "dev_scheduler_enabled" {
  type    = bool
  default = false
}

variable "observability" {
  type = object({
    enabled      = optional(bool, true)
    alarm_emails = optional(list(string), [])
  })
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
