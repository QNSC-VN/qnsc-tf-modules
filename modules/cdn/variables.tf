variable "name" {
  type        = string
  description = "Unique name prefix for all resources (e.g. <product>-web-develop)"
}

variable "acm_cert_arn" {
  type    = string
  default = null
  description = <<-EOT
    ACM certificate ARN for the CloudFront distribution.
    IMPORTANT: must be created in us-east-1 (CloudFront global requirement).
    Required when aliases is non-empty. When aliases = [], leave null to use
    the default *.cloudfront.net certificate.
  EOT
}

variable "aliases" {
  type        = list(string)
  default     = []
  description = "Custom domain aliases (e.g. [\"app.example.com\"])"
}

variable "price_class" {
  type        = string
  default     = "PriceClass_200"
  description = "CloudFront price class. PriceClass_200 covers US/EU/Asia (good default). PriceClass_All for global."

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "api_origin_domain_name" {
  type        = string
  default     = null
  description = <<-EOT
    Optional ALB/API DNS name. When set, adds a second CloudFront origin and an
    ordered cache behavior that forwards /v1/* to the API backend without caching.
    This lets the web SPA use relative API paths (/v1/…) so CORS and mixed-content
    are not issues — web and API share the same CloudFront domain.
    Leave null to serve static assets only (default).
  EOT
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    Allow the web S3 bucket to be destroyed even when it still contains objects.
    SPA build output is ephemeral and re-deployable, so set true in dev (and
    optionally prod) to make teardown clean without a manual `aws s3 rm`.
    Defaults false for safety.
  EOT
}

variable "tags" {
  type    = map(string)
  default = {}
}
