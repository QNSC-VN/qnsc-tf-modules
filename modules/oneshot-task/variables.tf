variable "name" {
  type        = string
  description = "Task definition family + log group suffix (e.g. \"rally-develop-migrator\")."
}

variable "container_name" {
  type        = string
  default     = "task"
  description = "Container name inside the task definition (e.g. \"migrator\")."
}

variable "image" {
  type        = string
  description = "Container image URI (e.g. <acct>.dkr.ecr.<region>.amazonaws.com/rally-migrator:latest)."
}

variable "command" {
  type        = list(string)
  default     = []
  description = "Optional container command override. Empty = use the image's default CMD."
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "execution_role_arn" {
  type        = string
  description = "ECS execution role (pull image, read secrets, write logs)."
}

variable "task_role_arn" {
  type        = string
  description = "ECS task role (the permissions the running task itself has)."
}

variable "region" {
  type        = string
  description = "AWS region for the awslogs driver."
}

variable "environment" {
  type        = map(string)
  default     = {}
  description = "Plain environment variables (name → value). Product-specific — the module doesn't interpret them."
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "Secret environment variables (name → Secrets Manager ARN). Product-specific."
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention (7 in dev, 90 in prod for SOC 2)."
}

variable "tags" {
  type    = map(string)
  default = {}
}
