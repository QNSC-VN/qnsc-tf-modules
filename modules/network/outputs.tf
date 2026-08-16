output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID."
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "Public subnet IDs."
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "Private subnet IDs (ECS tasks)."
}

output "data_subnet_ids" {
  value       = [for s in aws_subnet.data : s.id]
  description = "Data subnet IDs (RDS, cache)."
}

output "sg_alb_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID."
}

output "sg_app_id" {
  value       = aws_security_group.app.id
  description = "App (ECS) security group ID."
}

output "sg_rds_id" {
  value       = aws_security_group.rds.id
  description = "RDS security group ID."
}

output "sg_cache_id" {
  value       = aws_security_group.cache.id
  description = "Cache (Valkey/Redis/ElastiCache) security group ID."
}

output "nat_instance_id" {
  description = <<-EOT
    Instance id of the NAT box, or null when nat_type is not "instance".

    Exposed so the SSM port-forward command can be scripted or printed by the caller —
    it is the `--target` argument, and hunting for it in the console is the small friction
    that stops people using the safe path.
  EOT
  value       = var.nat_type == "instance" ? aws_instance.nat[0].id : null
}
