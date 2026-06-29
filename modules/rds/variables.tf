variable "identifier" {
  type        = string
  description = "DB instance identifier."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Data-tier subnet IDs for the DB subnet group."
}

variable "security_group_id" {
  type        = string
  description = "Security group for the DB instance."
}

variable "engine_version" {
  type        = string
  default     = "17"
  description = "Postgres major version (e.g. \"17\", \"18\")."
}

variable "instance_class" {
  type        = string
  description = "RDS instance class (e.g. db.t4g.medium, db.r7g.large)."
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "max_allocated_storage_gb" {
  type    = number
  default = 100
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "master_username" {
  type    = string
  default = "app_admin"
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "CMK ARN for storage encryption. Empty uses the AWS-managed key."
}

variable "monitoring_interval" {
  type        = number
  default     = 0
  description = "Enhanced Monitoring interval in seconds (0 = disabled; 60 recommended in prod)."
}

variable "enable_parameter_group" {
  type        = bool
  default     = true
  description = "Create a parameter group with pg_stat_statements + query/connection logging."
}

variable "log_min_duration_ms" {
  type        = number
  default     = 1000
  description = "Log statements slower than this (ms). Used by the parameter group."
}

variable "tags" {
  type    = map(string)
  default = {}
}
