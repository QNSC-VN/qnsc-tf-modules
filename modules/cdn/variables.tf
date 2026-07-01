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

variable "tags" {
  type    = map(string)
  default = {}
}
