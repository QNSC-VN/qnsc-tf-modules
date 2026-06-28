variable "prefix" {
  type        = string
  description = "Namespace prefix for secret/parameter names (e.g. \"myproduct/develop\")."
}

variable "secret_names" {
  type        = map(string)
  description = <<-EOT
    Map of secret key → human-readable description. One empty Secrets Manager
    secret is created per entry, named "<prefix>/<key>". Values are set
    out-of-band.
  EOT
}

variable "ssm_parameters" {
  type = map(object({
    value       = string
    description = string
  }))
  default     = {}
  description = "Non-sensitive config to store in SSM Parameter Store (key → {value, description})."
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS key ARN for encrypting secrets. Empty string uses the AWS-managed key."
}

variable "recovery_window_days" {
  type        = number
  default     = 7
  description = "Days before a deleted secret is permanently removed (0 = immediate delete)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all secrets and parameters."
}
