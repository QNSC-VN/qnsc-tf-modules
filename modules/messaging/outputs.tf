output "queue_urls" {
  value       = { for k, v in aws_sqs_queue.main : k => v.url }
  description = "Map of queue short name → URL."
}

output "queue_arns" {
  value       = { for k, v in aws_sqs_queue.main : k => v.arn }
  description = "Map of queue short name → ARN."
}

output "dlq_arns" {
  value       = { for k, v in aws_sqs_queue.dlq : k => v.arn }
  description = "Map of queue short name → DLQ ARN."
}

output "topic_arns" {
  value       = { for k, v in aws_sns_topic.events : k => v.arn }
  description = "Map of topic short name → ARN."
}
