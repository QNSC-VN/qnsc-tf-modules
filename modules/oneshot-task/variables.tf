variable "name" {
  type        = string
  description = "Task definition family + log group suffix (e.g. \"rova-develop-migrator\")."
}

variable "container_name" {
  type        = string
  default     = "task"
  description = "Container name inside the task definition (e.g. \"migrator\")."
}

variable "image" {
  type        = string
  description = "Container image URI (e.g. <acct>.dkr.ecr.<region>.amazonaws.com/rova-migrator:latest)."
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

variable "cpu_architecture" {
  type        = string
  default     = "X86_64"
  description = <<-EOT
    Fargate CPU architecture: "X86_64" or "ARM64". Must match the architecture
    `var.image` was built for; an x86 image on an ARM64 task fails at container start.
    Keep it equal to the ecs-service value in the same environment, since both images
    come out of the same build. Defaults to X86_64 so existing callers are unaffected.
  EOT

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
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
