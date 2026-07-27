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

variable "release_tag_prefix" {
  type        = string
  default     = "v"
  description = "Tag prefix for release images (the tags production pins)."
}

variable "keep_release_count" {
  type        = number
  default     = 30
  description = <<-EOT
    Most-recent RELEASE images to keep. This is the rollback depth for production, so
    it is generous on purpose: these are the tags a running task may re-pull.
  EOT
}

variable "build_tag_prefix" {
  type        = string
  default     = "sha-"
  description = "Tag prefix for per-commit build images."
}

variable "keep_build_count" {
  type        = number
  default     = 20
  description = <<-EOT
    Most-recent per-commit BUILD images to keep. Trimmed harder than releases: on a
    busy repo these accumulate at several per day and nothing pins them once the
    commit is superseded.
  EOT
}

variable "untagged_expire_days" {
  type        = number
  default     = 1
  description = <<-EOT
    Delete untagged images older than this many days.

    Note this does NOT catch the provenance/SBOM attestation manifests buildx pushes.
    ECR reports them as untagged, but they are referenced by the image index of a
    tagged image, so ECR keeps them alive with their parent. That is correct — they
    are the attestations for an image you are still keeping.
  EOT
}

variable "allowed_principal_arns" {
  type        = list(string)
  default     = []
  description = "IAM principal ARNs allowed to push/pull. Empty = no repository policy created."
}

variable "force_delete" {
  type        = bool
  default     = false
  description = <<-EOT
    Allow repositories to be deleted even when they still contain images.
    Set true so a full teardown (dev, or a from-scratch rebuild) doesn't require
    manually deleting images first. Defaults false for safety in long-lived envs.
  EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all repositories."
}
