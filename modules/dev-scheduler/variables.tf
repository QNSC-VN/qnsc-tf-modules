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
