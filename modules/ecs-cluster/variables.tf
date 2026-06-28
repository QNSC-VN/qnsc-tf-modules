variable "name" {
  type        = string
  description = "ECS cluster name."
}

variable "container_insights" {
  type        = string
  default     = "enhanced"
  description = "CloudWatch Container Insights mode: \"enhanced\", \"enabled\", or \"disabled\"."

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
