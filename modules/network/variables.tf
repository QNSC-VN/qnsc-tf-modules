variable "name" {
  type        = string
  description = "Name prefix for all network resources."
}

variable "region" {
  type        = string
  description = "AWS region (used for VPC endpoint service names)."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones; one public/private/data subnet is created per AZ."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets, ordered to match azs."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets, ordered to match azs."
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for data subnets, ordered to match azs."
}

variable "app_port" {
  type        = number
  default     = 3000
  description = "Port the app listens on (ALB → app ingress rule)."
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the ALB on 80/443."
}

variable "nat_type" {
  type        = string
  default     = "gateway"
  description = <<-EOT
    NAT egress type for private subnets.
      "gateway"  — AWS managed NAT Gateway (~$33/mo). Use for prod (reliability, no ops).
      "instance" — fck-nat t4g.nano EC2 (~$3/mo). Use for dev (single AZ, saves ~$30/mo).
  EOT
  validation {
    condition     = contains(["gateway", "instance", "none"], var.nat_type)
    error_message = "nat_type must be 'gateway', 'instance' or 'none'."
  }
}

variable "multi_az_nat" {
  type        = bool
  default     = false
  description = "One NAT gateway per AZ (HA, prod) vs a single NAT. Ignored when nat_type = 'instance'."
}

variable "enable_interface_endpoints" {
  type        = bool
  default     = true
  description = <<-EOT
    Create Interface VPC endpoints (ecr.api, ecr.dkr, secretsmanager). These cost
    ~$7.20/mo each and reduce NAT data cost in prod. In dev (which already has a
    NAT) they are redundant — set false to save cost. S3 gateway endpoint is free
    and always created.
  EOT
}

variable "enable_flow_logs" {
  type        = bool
  default     = true
  description = "Capture VPC flow logs to CloudWatch (audit trail)."
}

variable "flow_log_retention_days" {
  type        = number
  default     = 30
  description = "Retention for the VPC flow log group."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
