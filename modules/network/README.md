# `network` module

VPC with 3-tier subnets (public/private/data) per AZ, NAT (single or per-AZ),
route tables, security groups (alb/app/rds/cache), VPC endpoints, and flow logs.
Security-group rules use the modern standalone `aws_vpc_security_group_*_rule`
resources.

## Usage

```hcl
module "network" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/network?ref=network-v1.0.0"

  name                 = "myproduct-prod"
  region               = "ap-southeast-1"
  azs                  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  vpc_cidr             = "10.40.0.0/16"
  public_subnet_cidrs  = ["10.40.0.0/24", "10.40.1.0/24", "10.40.2.0/24"]
  private_subnet_cidrs = ["10.40.10.0/24", "10.40.11.0/24", "10.40.12.0/24"]
  data_subnet_cidrs    = ["10.40.20.0/24", "10.40.21.0/24", "10.40.22.0/24"]

  multi_az_nat               = true   # prod HA; false in dev
  enable_interface_endpoints = true   # prod; false in dev to save ~$22/mo
  tags                       = { Environment = "prod" }
}
```

## Cost note (dev)

In **dev**, set `multi_az_nat = false` and `enable_interface_endpoints = false`.
Dev already routes egress through a NAT, so the interface endpoints (ecr.api,
ecr.dkr, secretsmanager) are redundant — disabling them saves ~$22/mo. The free
S3 gateway endpoint stays.

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :------ | :---------- |
| `name` | `string` | — | Name prefix |
| `region` | `string` | — | AWS region |
| `vpc_cidr` | `string` | — | VPC CIDR |
| `azs` | `list(string)` | — | AZs (subnet per AZ) |
| `public_subnet_cidrs` | `list(string)` | — | Public CIDRs (match azs order) |
| `private_subnet_cidrs` | `list(string)` | — | Private CIDRs |
| `data_subnet_cidrs` | `list(string)` | — | Data CIDRs |
| `app_port` | `number` | `3000` | App listen port |
| `alb_ingress_cidrs` | `list(string)` | `["0.0.0.0/0"]` | CIDRs allowed to the ALB |
| `multi_az_nat` | `bool` | `false` | NAT per AZ vs single |
| `enable_interface_endpoints` | `bool` | `true` | Create paid interface endpoints |
| `enable_flow_logs` | `bool` | `true` | VPC flow logs |
| `flow_log_retention_days` | `number` | `30` | Flow log retention |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

`vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `data_subnet_ids`,
`sg_alb_id`, `sg_app_id`, `sg_rds_id`, `sg_cache_id`.

## Requirements

- OpenTofu / Terraform `>= 1.9.0`
- AWS provider `>= 5.0`
