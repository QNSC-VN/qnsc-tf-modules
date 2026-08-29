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

output "cluster_id" {
  # Node mode only: the CloudWatch `CacheClusterId` dimension every AWS/ElastiCache
  # metric (CPU, FreeableMemory, Evictions, ...) is published under. `member_clusters`
  # is the provider's own list of the actual created cluster ids — not a guessed
  # "<replication_group_id>-001" string, which is the same "resource id vs published
  # dimension" trap the observability module's rds_instance_id validation exists for.
  #
  # null for serverless: ElastiCache Serverless publishes a DIFFERENT metric set
  # (ElastiCacheProcessingUnits, BytesUsedForCache — no FreeableMemory/Evictions in the
  # same shape), so the observability module's cache alarms are node-mode only for now.
  value       = local.node ? one(aws_elasticache_replication_group.this[0].member_clusters) : null
  description = "CloudWatch CacheClusterId dimension (node mode only; null for serverless)."
}
