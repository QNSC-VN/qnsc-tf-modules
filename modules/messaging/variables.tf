variable "prefix" {
  type        = string
  description = "Name prefix for all queues and topics (e.g. \"myproduct-develop\")."
}

variable "queues" {
  type = map(object({
    visibility_timeout = optional(number, 30)
  }))
  default     = {}
  description = <<-EOT
    Main SQS queues to create (each gets a matching DLQ + redrive policy).
    Key = queue short name; value = optional per-queue config.
    Example: { notifications = {}, audit = { visibility_timeout = 60 } }
  EOT
}

variable "topics" {
  type        = list(string)
  default     = []
  description = "SNS topic short names to create (named \"<prefix>-<name>\")."
}

variable "subscriptions" {
  type = list(object({
    topic         = string
    queue         = string
    filter_policy = optional(string, "")
  }))
  default     = []
  description = <<-EOT
    SNS→SQS subscriptions. Each references a topic and queue short name defined
    above. filter_policy is an optional JSON string.
  EOT
}

variable "create_queue_policies" {
  type        = bool
  default     = true
  description = "Create SQS queue policies allowing SNS topics under this prefix to publish."
}

variable "dlq_max_receive_count" {
  type        = number
  default     = 5
  description = "Receives before a message is moved to its DLQ."
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS key ARN for SNS topics. Empty uses the AWS-managed key (alias/aws/sns)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
