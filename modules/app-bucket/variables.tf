variable "name" {
  type        = string
  description = "Bucket name (e.g. \"rova-develop-attachments\")."
}

variable "kms_key_arn" {
  type        = string
  description = "CMK ARN for SSE-KMS at rest."
}

variable "versioning" {
  type        = bool
  default     = false
  description = "Enable object versioning."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow destroy with objects present (dev). Default false for safety."
}

variable "cors_rules" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default     = []
  description = "CORS rules (e.g. for browser presigned PUT uploads). Empty = no CORS config."
}

variable "lifecycle_rules" {
  type = list(object({
    id              = string
    prefix          = optional(string, "")
    expiration_days = optional(number)
    noncurrent_days = optional(number)
  }))
  default     = []
  description = "Lifecycle rules. Each may set expiration_days and/or noncurrent_days."
}

variable "tags" {
  type    = map(string)
  default = {}
}
