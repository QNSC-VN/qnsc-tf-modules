variable "bucket_name" {
  type        = string
  description = "S3 bucket name for ALB access logs (globally unique)."
}

variable "retention_days" {
  type        = number
  default     = 90
  description = "Days to keep access logs before expiry."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow bucket deletion even when it contains logs (use false in prod)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the bucket."
}
