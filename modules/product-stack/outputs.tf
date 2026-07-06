# Rich handles so a product stack can bolt on quirks alongside this module.

# Network
output "vpc_id" { value = module.network.vpc_id }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "data_subnet_ids" { value = module.network.data_subnet_ids }
output "sg_app_id" { value = module.network.sg_app_id }
output "sg_alb_id" { value = module.network.sg_alb_id }

# ALB
output "alb_arn" { value = module.alb.arn }
output "alb_dns_name" { value = module.alb.dns_name }
output "alb_zone_id" { value = module.alb.zone_id }
output "alb_https_listener_arn" { value = module.alb.https_listener_arn }
output "alb_http_listener_arn" { value = module.alb.http_listener_arn }

# ECS
output "cluster_name" { value = module.ecs_cluster.cluster_name }
output "cluster_arn" { value = module.ecs_cluster.cluster_arn }
output "service_execution_role_arns" {
  value = { for k, s in module.services : k => s.execution_role_arn }
}
output "service_task_role_arns" {
  value = { for k, s in module.services : k => s.task_role_arn }
}
output "service_target_group_arns" {
  value = { for k, s in module.services : k => s.target_group_arn }
}

# Data stores
output "rds_endpoint" { value = module.rds.endpoint }
output "cache_endpoint" { value = module.cache.endpoint }
output "queue_urls" { value = module.messaging.queue_urls }
output "topic_arns" { value = module.messaging.topic_arns }
output "secret_arns" { value = module.secrets.secret_arns }

# App buckets
output "app_bucket_names" {
  value = { for k, b in module.app_buckets : k => b.bucket }
}

# CDN
output "cloudfront_domain" {
  value = var.cdn.enabled ? module.cdn[0].cloudfront_domain : null
}
output "cloudfront_id" {
  value = var.cdn.enabled ? module.cdn[0].cloudfront_id : null
}
output "web_bucket_name" {
  value = var.cdn.enabled ? module.cdn[0].bucket_name : null
}
