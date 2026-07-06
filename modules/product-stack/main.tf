# See variables.tf for the design rationale. Sibling modules are referenced by
# relative path (intra-repo composition) so a product pinning product-stack@vX
# transitively gets that revision's building blocks — always version-consistent.

locals {
  name          = "${var.product}-${var.env}"
  messaging_kms = coalesce(try(var.messaging.kms_key_arn, null), var.kms_key_arn)
}

# ── Networking ───────────────────────────────────────────────────────────────
module "network" {
  source = "../network"

  name   = local.name
  region = var.region
  azs    = var.azs

  vpc_cidr             = var.network.vpc_cidr
  public_subnet_cidrs  = var.network.public_subnet_cidrs
  private_subnet_cidrs = var.network.private_subnet_cidrs
  data_subnet_cidrs    = var.network.data_subnet_cidrs

  app_port                   = var.network.app_port
  nat_type                   = var.network.nat_type
  multi_az_nat               = var.network.multi_az_nat
  enable_flow_logs           = var.network.enable_flow_logs
  flow_log_retention_days    = var.network.flow_log_retention_days
  enable_interface_endpoints = var.network.enable_interface_endpoints
  alb_ingress_cidrs          = length(var.network.alb_ingress_cidrs) > 0 ? var.network.alb_ingress_cidrs : ["0.0.0.0/0"]

  tags = merge(var.tags, { Environment = var.env })
}

# ── Secrets ──────────────────────────────────────────────────────────────────
module "secrets" {
  source = "../secrets"

  prefix               = "${var.product}/${var.env}"
  kms_key_arn          = var.kms_key_arn
  recovery_window_days = var.secrets_recovery_window_days
  secret_names         = var.secret_names
  tags                 = merge(var.tags, { Environment = var.env })
}

# ── RDS ──────────────────────────────────────────────────────────────────────
module "rds" {
  source = "../rds"

  identifier        = local.name
  subnet_ids        = module.network.data_subnet_ids
  security_group_id = module.network.sg_rds_id
  kms_key_arn       = var.kms_key_arn

  instance_class           = var.rds.instance_class
  allocated_storage_gb     = var.rds.allocated_storage_gb
  max_allocated_storage_gb = var.rds.max_allocated_storage_gb
  multi_az                 = var.rds.multi_az
  deletion_protection      = var.rds.deletion_protection
  backup_retention_days    = var.rds.backup_retention_days
  monitoring_interval      = var.rds.monitoring_interval

  tags = merge(var.tags, { Environment = var.env }, var.rds.multi_az ? {} : { AutoStop = "true" })
}

# ── Cache ──────────────────────────────────────────────────────────────────
module "cache" {
  source = "../cache"

  name              = local.name
  subnet_ids        = module.network.data_subnet_ids
  security_group_id = module.network.sg_cache_id
  mode              = var.cache.mode

  tags = merge(var.tags, { Environment = var.env })
}

# ── Messaging ────────────────────────────────────────────────────────────────
module "messaging" {
  source = "../messaging"

  prefix        = local.name
  queues        = var.messaging.queues
  topics        = var.messaging.topics
  subscriptions = var.messaging.subscriptions
  kms_key_arn   = local.messaging_kms

  tags = merge(var.tags, { Environment = var.env })
}

# ── ALB ──────────────────────────────────────────────────────────────────────
module "alb" {
  source = "../alb"

  name               = local.name
  security_group_ids = [module.network.sg_alb_id]
  subnet_ids         = module.network.public_subnet_ids
  certificate_arn    = var.alb.certificate_arn

  enable_deletion_protection = var.alb.enable_deletion_protection
  access_logs_bucket         = try(var.alb.access_logs_bucket, null)

  tags = merge(var.tags, { Environment = var.env })
}

# ── ECS cluster ──────────────────────────────────────────────────────────────
module "ecs_cluster" {
  source = "../ecs-cluster"
  name   = local.name
  tags   = merge(var.tags, { Environment = var.env })
}

# ── ECS services (api, worker, …) ────────────────────────────────────────────
module "services" {
  source   = "../ecs-service"
  for_each = var.services

  service_name = each.key
  cluster_name = module.ecs_cluster.cluster_name
  cluster_arn  = module.ecs_cluster.cluster_arn
  region       = var.region
  image_uri    = each.value.image_uri

  cpu    = each.value.cpu
  memory = each.value.memory

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.network.sg_app_id

  desired_count      = each.value.desired_count
  min_count          = each.value.min_count
  max_count          = each.value.max_count
  use_spot           = each.value.use_spot
  log_retention_days = each.value.log_retention_days

  attach_alb        = each.value.attach_alb
  alb_listener_arn  = each.value.attach_alb ? module.alb.https_listener_arn : null
  alb_priority      = each.value.alb_priority
  alb_path_patterns = each.value.alb_path_patterns
  health_check_path = each.value.health_check_path

  secret_arns      = values(module.secrets.secret_arns)
  kms_key_arn      = var.kms_key_arn
  secrets          = each.value.secrets
  environment_vars = each.value.environment_vars

  tags = merge(var.tags, { Environment = var.env }, each.value.autostop ? { AutoStop = "true" } : {})
}

# ── Migrator (one-shot) — reuses a service's IAM roles ───────────────────────
module "migrator" {
  source = "../oneshot-task"
  count  = var.migrator.enabled ? 1 : 0

  name               = "${local.name}-migrator"
  container_name     = "migrator"
  image              = var.migrator.image_uri
  cpu                = var.migrator.cpu
  memory             = var.migrator.memory
  execution_role_arn = module.services[var.migrator.roles_from_service].execution_role_arn
  task_role_arn      = module.services[var.migrator.roles_from_service].task_role_arn
  region             = var.region
  log_retention_days = var.migrator.log_retention_days

  tags = merge(var.tags, { Environment = var.env })
}

# ── App buckets (uploads / attachments) ──────────────────────────────────────
module "app_buckets" {
  source   = "../app-bucket"
  for_each = var.app_buckets

  name            = "${local.name}-${each.key}"
  kms_key_arn     = var.kms_key_arn
  versioning      = each.value.versioning
  force_destroy   = each.value.force_destroy
  cors_rules      = each.value.cors_rules
  lifecycle_rules = each.value.lifecycle_rules
  tags            = merge(var.tags, { Environment = var.env })
}

# ── WAF (regional, ALB) ──────────────────────────────────────────────────────
module "waf" {
  source = "../waf"

  name                = local.name
  enabled             = var.waf.enabled
  scope               = "REGIONAL"
  alb_arn             = module.alb.arn
  rate_limit_per_5min = var.waf.rate_limit_per_5min
  log_retention_days  = var.waf.log_retention_days

  tags = merge(var.tags, { Environment = var.env })
}

# ── CDN (web SPA) ────────────────────────────────────────────────────────────
module "cdn" {
  source = "../cdn"
  count  = var.cdn.enabled ? 1 : 0

  name                   = var.cdn.bucket_name
  aliases                = var.cdn.aliases
  acm_cert_arn           = var.cdn.acm_cert_arn
  price_class            = var.cdn.price_class
  api_origin_domain_name = var.cdn.api_origin_domain_name
  web_acl_arn            = var.cdn.web_acl_arn
  force_destroy          = var.cdn.force_destroy

  tags = merge(var.tags, { Environment = var.env, Service = "web" })
}

# ── DNS records (Cloudflare) ─────────────────────────────────────────────────
module "dns" {
  source   = "../dns-record"
  for_each = var.cloudflare_zone_id != "" ? var.dns_records : {}

  enabled = true
  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  comment = each.value.comment
}

# ── Observability — alarms + dashboard (golden signals) ──────────────────────
module "observability" {
  source = "../observability"
  count  = var.observability.enabled ? 1 : 0

  name              = local.name
  region            = var.region
  alarm_emails      = var.observability.alarm_emails
  ecs_cluster_name  = module.ecs_cluster.cluster_name
  ecs_service_names = keys(var.services)
  alb_arn           = module.alb.arn
  rds_instance_id   = local.name
  tags              = merge(var.tags, { Environment = var.env })
}

# ── Dev cost-saver scheduler ─────────────────────────────────────────────────
module "dev_scheduler" {
  source = "../dev-scheduler"
  count  = var.dev_scheduler_enabled ? 1 : 0

  name = local.name
  tags = merge(var.tags, { Environment = var.env })
}
