variable "name" {
  type        = string
  description = "Name prefix for the scheduler resources (e.g. \"myproduct-develop\")."
}

variable "tag_key" {
  type        = string
  default     = "AutoStop"
  description = "Tag key a resource must have to be stopped/started."
}

variable "tag_value" {
  type        = string
  default     = "true"
  description = "Tag value required alongside tag_key."
}

variable "stop_cron" {
  type        = string
  default     = "cron(0 20 ? * MON-FRI *)"
  description = "When to stop dev (EventBridge cron). Default: 20:00 weekdays."
}

variable "start_cron" {
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
  description = "When to start dev (EventBridge cron). Default: 08:00 weekdays."
}

variable "timezone" {
  type        = string
  default     = "Asia/Ho_Chi_Minh"
  description = "IANA timezone the cron expressions are evaluated in."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to scheduler resources."
}

variable "rds_wait_timeout" {
  type        = number
  default     = 480
  description = <<-EOT
    Seconds the "start" Lambda waits for RDS to become available before it
    scales ECS back up. A cold RDS start typically takes 3-8 minutes.
  EOT
}

variable "lambda_timeout" {
  type        = number
  default     = 600
  description = <<-EOT
    Lambda function timeout (seconds). MUST be greater than rds_wait_timeout,
    otherwise the "start" action is killed while waiting for RDS and never
    scales ECS. Max allowed by AWS is 900.
  EOT

  validation {
    condition     = var.lambda_timeout > var.rds_wait_timeout && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be greater than rds_wait_timeout and at most 900."
  }
}
