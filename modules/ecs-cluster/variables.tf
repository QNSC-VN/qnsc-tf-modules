variable "name" {
  type        = string
  description = "ECS cluster name."
}

variable "container_insights" {
  type        = string
  default     = "enabled"
  description = <<-EOT
    CloudWatch Container Insights mode: "enhanced", "enabled", or "disabled".

    Defaults to "enabled" (cluster- and service-level metrics). It used to default to
    "enhanced", which adds per-task and per-container metrics that CloudWatch bills as
    CUSTOM metrics at $0.07 each: four clusters silently inheriting that default
    produced 606 metric-months (~$42) on the July 2026 bill, and the count scales with
    task churn rather than with traffic. Ask for "enhanced" per environment while
    debugging a container-level resource problem, then put it back.
  EOT

  validation {
    condition     = contains(["enhanced", "enabled", "disabled"], var.container_insights)
    error_message = "container_insights must be enhanced, enabled, or disabled."
  }
}

variable "fargate_base" {
  type        = number
  default     = 1
  description = "Minimum number of tasks to run on FARGATE before applying the weight."
}

variable "fargate_weight" {
  type        = number
  default     = 100
  description = "Relative weight for FARGATE in the default capacity provider strategy."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the cluster."
}
