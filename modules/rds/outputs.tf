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
  description = "DB instance identifier."
}

output "instance_arn" {
  value       = aws_db_instance.this.arn
  description = "DB instance ARN."
}

output "master_secret_arn" {
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  description = "ARN of the RDS-managed master password secret in Secrets Manager."
}
