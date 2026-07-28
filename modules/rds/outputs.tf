output "endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "Connection endpoint (host:port)."
}

output "address" {
  value       = aws_db_instance.this.address
  description = "DB hostname."
}

output "port" {
  value       = aws_db_instance.this.port
  description = "DB port."
}

output "db_name" {
  value       = aws_db_instance.this.db_name
  description = "Initial database name."
}

output "instance_id" {
  value       = aws_db_instance.this.id
  description = <<-EOT
    RESOURCE id (`db-XXXXXXXX…`), not the identifier — despite the name.

    In AWS provider 5.x `aws_db_instance.id` returns the resource id; it returned the
    identifier in provider 4. The name and the old description both said "identifier",
    which is how six CloudWatch alarms ended up wired to a dimension value RDS never
    publishes, sitting in INSUFFICIENT_DATA forever while appearing to monitor the
    database.

    For a CloudWatch `DBInstanceIdentifier` dimension, or anything else a human types,
    use `identifier` below. This output is kept for callers that genuinely want the
    resource id (Performance Insights, some IAM resource ARNs).
  EOT
}

output "identifier" {
  value       = aws_db_instance.this.identifier
  description = "DB instance identifier (e.g. `rally-prod`) — the CloudWatch DBInstanceIdentifier dimension value."
}

output "instance_arn" {
  value       = aws_db_instance.this.arn
  description = "DB instance ARN."
}

output "master_secret_arn" {
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  description = "ARN of the RDS-managed master password secret in Secrets Manager."
}
