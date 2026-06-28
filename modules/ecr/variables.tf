variable "repository_names" {
  type        = list(string)
  description = "ECR repository names to create."
}

variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "IMMUTABLE (recommended) or MUTABLE (allows re-tagging e.g. :latest)."

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS key ARN for encryption. Empty string uses AES256 (AWS-managed)."
}

variable "keep_tagged_count" {
  type        = number
  default     = 30
  description = "Number of most-recent tagged images to keep per repo."
}

variable "untagged_expire_days" {
  type        = number
  default     = 1
  description = "Delete untagged images older than this many days."
}

variable "tag_prefix_list" {
  type        = list(string)
  default     = ["sha-", "v"]
  description = "Tag prefixes the keep-count lifecycle rule applies to."
}

variable "allowed_principal_arns" {
  type        = list(string)
  default     = []
  description = "IAM principal ARNs allowed to push/pull. Empty = no repository policy created."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all repositories."
}
