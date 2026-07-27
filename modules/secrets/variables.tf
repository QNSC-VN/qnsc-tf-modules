variable "prefix" {
  type        = string
  description = "Namespace prefix for secret/parameter names (e.g. \"myproduct/develop\")."
}

variable "secret_names" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Map of secret key → human-readable description. One empty Secrets Manager
    secret is created per entry, named "<prefix>/<key>". Values are set
    out-of-band.

    Defaults to empty, because `secure_parameters` is the cheaper default home for
    ordinary app secrets. Use this only for values that need something Parameter
    Store cannot do: rotation, cross-region replication, a resource policy, or more
    than 4 KB.
  EOT
}

variable "secure_parameters" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Sensitive values to create as SSM SecureString parameters: key => description.

    Preferred over `secret_names` for ordinary app secrets — standard SSM parameters
    carry no per-parameter monthly charge, where Secrets Manager is $0.40 each. Same
    CMK encryption, same one-ARN-per-value IAM granularity, and ECS reads both the
    same way.

    Created holding the literal "UNSET" (SSM forbids an empty value) with
    ignore_changes on the value, so the real material is pasted in out of band and
    Terraform never reverts it. A parameter still at version 1 has never been
    populated; CI gates on that.

    Reach for `secret_names` instead when a value needs rotation, replication, a
    resource policy, or is larger than the 4 KB standard-parameter limit.
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
