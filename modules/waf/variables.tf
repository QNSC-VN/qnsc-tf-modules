variable "name" {
  type        = string
  description = "Name prefix for the WebACL and its metrics/logs."
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Create the WebACL + association + logging. False disables WAF entirely."
}

variable "alb_arn" {
  type        = string
  default     = ""
  description = "ALB ARN to associate. Empty = create the ACL but don't associate."
}

variable "rate_limit_per_5min" {
  type        = number
  default     = 2000
  description = "Requests per IP per 5 minutes before the rate-based rule blocks."
}

variable "log_retention_days" {
  type        = number
  default     = 90
  description = "Retention for the WAF CloudWatch log group."
}

variable "tags" {
  type    = map(string)
  default = {}
}
