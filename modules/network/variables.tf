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
    condition     = contains(["gateway", "instance"], var.nat_type)
    error_message = "nat_type must be 'gateway' or 'instance'."
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

variable "nat_ssm_bastion" {
  type    = bool
  default = false

  description = <<-EOT
    Attach an SSM instance profile to the NAT instance and allow it to reach RDS and the
    cache, so a developer can port-forward to them from a laptop:

        aws ssm start-session --target <nat-instance-id> \
          --document-name AWS-StartPortForwardingSessionToRemoteHost \
          --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["15432"]}'

    Then point DBeaver at localhost:15432. The databases stay `publicly_accessible =
    false`; there is no inbound port, no SSH key and no second instance to pay for,
    because the NAT already runs and already has the egress the SSM agent needs.

    OFF BY DEFAULT because it creates a path from a laptop to the data tier. That is
    reasonable for develop and a deliberate decision for production — so it is a choice
    someone makes per environment, in a diff, rather than a default nobody chose.

    Access is governed by IAM (who may call ssm:StartSession) rather than by the network,
    and every session appears in CloudTrail. That auditability is what an SSH bastion
    does not give you.

    NOTE for the cache: transit encryption is on, so the local end speaks TLS —
    `redis-cli --tls -h 127.0.0.1 -p 16379`. A plain connection is refused.
  EOT
}
