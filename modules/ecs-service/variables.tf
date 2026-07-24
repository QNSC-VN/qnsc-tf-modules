# ── Identity / placement ──────────────────────────────────────────────────────
variable "service_name" { type = string }
variable "cluster_name" { type = string }
variable "cluster_arn" { type = string }
variable "region" {
  type        = string
  description = "AWS region (for the awslogs driver)."
}

variable "image_uri" {
  type        = string
  description = "Container image URI (registry/name:tag)."
}

# ── Sizing ────────────────────────────────────────────────────────────────────
variable "cpu" { type = number }
variable "memory" { type = number }
variable "container_port" {
  type    = number
  default = 3000
}
variable "desired_count" {
  type    = number
  default = 1
}
variable "min_count" {
  type    = number
  default = 1
}
variable "max_count" {
  type    = number
  default = 4
}

# ── Autoscaling targets ───────────────────────────────────────────────────────
variable "cpu_target_pct" {
  type        = number
  default     = 65
  description = "Target average CPU % for autoscaling."
}
variable "memory_target_pct" {
  type        = number
  default     = 75
  description = "Target average memory % for autoscaling."
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }

# ── ALB attachment ────────────────────────────────────────────────────────────
variable "attach_alb" {
  type    = bool
  default = true
}
variable "alb_listener_arn" {
  type    = string
  default = ""
}
variable "alb_priority" {
  type    = number
  default = 100
}
variable "alb_path_patterns" {
  type    = list(string)
  default = ["/*"]
}
variable "alb_host_headers" {
  type        = list(string)
  default     = []
  description = "Host headers for the ALB listener rule. Set for shared-ALB host-based routing (e.g. [\"rally-api.qnsc.vn\"]); empty keeps the rule path-only."
}
variable "health_check_path" {
  type    = string
  default = "/health"
}
variable "health_check_command" {
  type    = string
  default = null
}

# ── Config / secrets ──────────────────────────────────────────────────────────
variable "environment_vars" {
  type    = list(object({ name = string, value = string }))
  default = []
}
variable "secrets" {
  type    = list(object({ name = string, secret_arn = string }))
  default = []
}
variable "secret_arns" {
  type        = list(string)
  default     = []
  description = "Secret ARNs the execution role may read (for secrets injection)."
}
variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "CMK ARN; if set, the execution role gets kms:Decrypt for KMS-encrypted secrets."
}

# ── Runtime AWS access (task role) ────────────────────────────────────────────
variable "sqs_queue_arns" {
  type    = list(string)
  default = []
}
variable "sns_topic_arns" {
  type    = list(string)
  default = []
}
variable "s3_bucket_arns" {
  type        = list(string)
  default     = []
  description = "S3 bucket ARNs the task may read/write (get/put/delete + list)."
}
variable "task_secret_arns" {
  type        = list(string)
  default     = []
  description = <<-EOT
    Secret ARNs (wildcards allowed) the TASK role may read at RUNTIME via
    secretsmanager:GetSecretValue — e.g. an app resolving per-connection
    credentials on demand from a DB-driven config. Distinct from `secret_arns`,
    which is the EXECUTION role reading secrets once at container start for env
    injection.
  EOT
}

# ── Misc ──────────────────────────────────────────────────────────────────────
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "enable_ecs_exec" {
  type        = bool
  default     = false
  description = "Enable ECS Exec (aws ecs execute-command) for debugging."
}
variable "use_spot" {
  type        = bool
  default     = false
  description = "Prefer FARGATE_SPOT (weight 4) with FARGATE fallback (weight 1). Saves ~70% on Fargate compute in dev."
}
variable "additional_containers" {
  type        = any
  default     = []
  description = "Extra sidecar container definitions merged into the task definition (e.g. a Valkey cache sidecar in dev). Each element is a full ECS container definition object; reachable from the app at localhost via the shared task network namespace."
}
variable "tags" {
  type    = map(string)
  default = {}
}
