# =============================================================================
# network — VPC, 3-tier subnets (public/private/data), NAT, route tables,
# security groups (alb/app/rds/cache), VPC endpoints, and flow logs.
#
# Security-group rules use the modern standalone resources
# (aws_vpc_security_group_*_rule) rather than inline blocks.
# =============================================================================

# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "${var.name}-vpc" })
}

# ── Subnets (public / private / data) ─────────────────────────────────────────
resource "aws_subnet" "public" {
  for_each                = { for i, az in var.azs : az => var.public_subnet_cidrs[i] }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name}-public-${each.key}", Tier = "public" })
}

resource "aws_subnet" "private" {
  for_each          = { for i, az in var.azs : az => var.private_subnet_cidrs[i] }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags              = merge(var.tags, { Name = "${var.name}-private-${each.key}", Tier = "private" })
}

resource "aws_subnet" "data" {
  for_each          = { for i, az in var.azs : az => var.data_subnet_cidrs[i] }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags              = merge(var.tags, { Name = "${var.name}-data-${each.key}", Tier = "data" })
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# ── NAT — Gateway (prod) or fck-nat instance (dev) ───────────────────────────
# nat_type = "gateway": AWS managed NAT Gateway — reliable, no ops, ~$33/mo.
# nat_type = "instance": fck-nat t4g.nano in first public subnet — ~$3/mo,
#   single AZ (acceptable for dev), community-maintained Graviton AMI.

locals {
  nat_azs = var.nat_type == "gateway" ? (var.multi_az_nat ? toset(var.azs) : toset([var.azs[0]])) : toset([])
}

resource "aws_eip" "nat" {
  for_each = local.nat_azs
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each      = local.nat_azs
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
  depends_on    = [aws_internet_gateway.this]
}

# fck-nat: community-maintained NAT instance AMI for Graviton (AL2023, arm64).
# Source: https://github.com/AndrewGuenther/fck-nat
# Uses aws_ami data source — SSM community namespace requires special permissions.
data "aws_ami" "fck_nat" {
  count       = var.nat_type == "instance" ? 1 : 0
  most_recent = true
  owners      = ["568608671756"] # fck-nat official AWS account

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-arm64-ebs"]
  }
}

resource "aws_security_group" "nat_instance" {
  count       = var.nat_type == "instance" ? 1 : 0
  name        = "${var.name}-nat-instance"
  description = "fck-nat instance - inbound from VPC, all outbound"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-sg-nat-instance" })
}

resource "aws_vpc_security_group_ingress_rule" "nat_from_vpc" {
  count             = var.nat_type == "instance" ? 1 : 0
  security_group_id = aws_security_group.nat_instance[0].id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "nat_to_all" {
  count             = var.nat_type == "instance" ? 1 : 0
  security_group_id = aws_security_group.nat_instance[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "nat" {
  count                  = var.nat_type == "instance" ? 1 : 0
  ami                    = data.aws_ami.fck_nat[0].id
  instance_type          = "t4g.nano"
  subnet_id              = aws_subnet.public[var.azs[0]].id
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]
  iam_instance_profile   = var.nat_ssm_bastion ? aws_iam_instance_profile.nat_ssm[0].name : null
  tags                   = merge(var.tags, { Name = "${var.name}-nat-instance" })
}

# ── SSM bastion on the NAT instance (opt-in) ─────────────────────────────────
# Turns the NAT box into a jump host for `aws ssm start-session
# --document-name AWS-StartPortForwardingSessionToRemoteHost`, so a developer can reach
# RDS and the cache from a laptop WITHOUT the databases being publicly accessible, an
# SSH key, an inbound port, or a second instance to pay for.
#
# The NAT already exists, already runs, and already has the egress the SSM agent needs.
# The alternatives all cost something: a dedicated bastion is another instance, an
# always-on cloudflared is another task, and a publicly-accessible RDS costs nothing
# until the day it costs everything.
#
# DELIBERATELY OPT-IN, default off. This grants a path from a laptop to the data tier,
# which is right for develop and a decision for production. Turning it on is a choice
# somebody makes per environment, in a diff.
#
# Access is controlled by IAM (who may call ssm:StartSession), not by the network, and
# every session is recorded in CloudTrail. That is the property SSH bastions lack.
resource "aws_iam_role" "nat_ssm" {
  count = var.nat_type == "instance" && var.nat_ssm_bastion ? 1 : 0

  name = "${var.name}-nat-ssm"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# The AWS-managed policy, not a hand-written one: it is exactly the set the SSM agent
# needs to register and hold a session, and it tracks changes to that contract.
resource "aws_iam_role_policy_attachment" "nat_ssm" {
  count = var.nat_type == "instance" && var.nat_ssm_bastion ? 1 : 0

  role       = aws_iam_role.nat_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_ssm" {
  count = var.nat_type == "instance" && var.nat_ssm_bastion ? 1 : 0

  name = "${var.name}-nat-ssm"
  role = aws_iam_role.nat_ssm[0].name
  tags = var.tags
}

# The port-forward terminates ON the NAT box and dials the data tier from there, so the
# data security groups must accept it. Scoped to the NAT's own security group — not a
# CIDR — so nothing else in the public subnet inherits database access.
resource "aws_vpc_security_group_ingress_rule" "rds_from_nat" {
  count = var.nat_type == "instance" && var.nat_ssm_bastion ? 1 : 0

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.nat_instance[0].id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "SSM port-forward jump host (nat_ssm_bastion)"
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_nat" {
  count = var.nat_type == "instance" && var.nat_ssm_bastion ? 1 : 0

  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = aws_security_group.nat_instance[0].id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "SSM port-forward jump host (nat_ssm_bastion)"
}

# ── Route tables ──────────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id

  dynamic "route" {
    for_each = var.nat_type == "gateway" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.multi_az_nat ? aws_nat_gateway.this[each.key].id : aws_nat_gateway.this[var.azs[0]].id
    }
  }

  dynamic "route" {
    for_each = var.nat_type == "instance" ? [1] : []
    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = aws_instance.nat[0].primary_network_interface_id
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-rt-private-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-rt-data" })
}

resource "aws_route_table_association" "data" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data.id
}

# ── Security groups ───────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "ALB - public ingress"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-sg-alb" })
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "ECS app tasks"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-sg-app" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "RDS - from app only"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-sg-rds" })
}

resource "aws_security_group" "cache" {
  name        = "${var.name}-cache"
  description = "Cache (Valkey/Redis) - from app only"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-sg-cache" })
}

# ALB ingress (HTTPS + HTTP) from the allowed CIDRs.
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each          = toset(var.alb_ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each          = toset(var.alb_ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# App: ingress from ALB on app_port + self-443 (for interface endpoints).
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_self_https" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS: ingress from app on 5432.
resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# Cache: ingress from app on 6379 + egress.
resource "aws_vpc_security_group_ingress_rule" "cache_from_app" {
  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "cache_all" {
  security_group_id = aws_security_group.cache.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── VPC endpoints ─────────────────────────────────────────────────────────────
# S3 Gateway endpoint is free — always created.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], values(aws_route_table.private)[*].id)
  tags              = merge(var.tags, { Name = "${var.name}-vpce-s3" })
}

# Interface endpoints cost ~$7.20/mo each. They reduce NAT data cost in prod,
# but in dev (which already has a NAT) they are redundant — toggle off.
locals {
  interface_endpoints = var.enable_interface_endpoints ? {
    "ecr-api"        = "com.amazonaws.${var.region}.ecr.api"
    "ecr-dkr"        = "com.amazonaws.${var.region}.ecr.dkr"
    "secretsmanager" = "com.amazonaws.${var.region}.secretsmanager"
  } : {}
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.app.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name}-vpce-${each.key}" })
}

# ── VPC flow logs (network traffic audit trail) ───────────────────────────────
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/vpc/flow-logs/${var.name}"
  retention_in_days = var.flow_log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream", "logs:PutLogEvents",
        "logs:DescribeLogGroups", "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count           = var.enable_flow_logs ? 1 : 0
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  tags            = merge(var.tags, { Name = "${var.name}-flow-logs" })
}
