# observability — SNS-backed CloudWatch alarms + a dashboard for the golden
# signals of an ECS-on-ALB-with-RDS service. Cheap (alarms ~$0.10/mo, dashboard
# ~$3/mo) and additive. Wire from product-stack with the handles it already has.

variable "name" { type = string }

variable "alarm_emails" {
  type        = list(string)
  default     = []
  description = "Emails subscribed to the alarm SNS topic. Empty = topic only (wire subscribers later)."
}

variable "region" { type = string }

variable "ecs_cluster_name" { type = string }
variable "ecs_service_names" {
  type    = list(string)
  default = []
}

variable "alb_arn" {
  type        = string
  default     = ""
  description = "Full ALB ARN; the CloudWatch LoadBalancer dimension is derived from it. Empty = skip ALB alarms."
}

variable "rds_instance_id" {
  type        = string
  default     = ""
  description = "RDS DBInstanceIdentifier. Empty = skip RDS alarms."
}

variable "thresholds" {
  type = object({
    ecs_cpu_pct     = optional(number, 85)
    ecs_mem_pct     = optional(number, 85)
    alb_5xx_count   = optional(number, 20)
    alb_latency_sec = optional(number, 2)
    rds_cpu_pct     = optional(number, 85)
    rds_free_bytes  = optional(number, 2147483648) # 2 GiB
    rds_connections = optional(number, 100)
  })
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
