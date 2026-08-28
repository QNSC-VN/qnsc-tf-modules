output "rule_group_uid" {
  value       = grafana_rule_group.this.id
  description = "The created rule group's id, for reference/debugging."
}
