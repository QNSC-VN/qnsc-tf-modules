output "endpoint" {
  value = local.serverless ? (
    aws_elasticache_serverless_cache.this[0].endpoint[0].address
    ) : (
    aws_elasticache_replication_group.this[0].primary_endpoint_address
  )
  description = "Primary cache endpoint address."
}

output "port" {
  value = local.serverless ? (
    aws_elasticache_serverless_cache.this[0].endpoint[0].port
  ) : 6379
  description = "Cache port."
}

output "reader_endpoint" {
  value = local.serverless ? (
    aws_elasticache_serverless_cache.this[0].reader_endpoint[0].address
    ) : (
    aws_elasticache_replication_group.this[0].reader_endpoint_address
  )
  description = "Reader endpoint address."
}
