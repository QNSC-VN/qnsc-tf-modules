variable "name" {
  type        = string
  description = "ALB name (e.g. \"rova-develop\")."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for the ALB (typically the network module's sg_alb_id)."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs the ALB spans."
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for the HTTPS listener (ap-southeast-1)."
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "SSL policy for the HTTPS listener."
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "Protect the ALB from deletion (true in prod, false in dev for easy teardown)."
}

variable "access_logs_bucket" {
  type        = string
  default     = ""
  description = "S3 bucket for ALB access logs (prod). Empty (default) disables access logging."
}

variable "tags" {
  type    = map(string)
  default = {}
}
