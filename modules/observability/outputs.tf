output "alarm_topic_arn" {
  value       = aws_sns_topic.alarms.arn
  description = "SNS topic all alarms publish to — subscribe PagerDuty/Slack/email."
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.this.dashboard_name
}
