output "bucket_id" {
  value       = aws_s3_bucket.logs.id
  description = "Name of the log bucket — pass to aws_lb access_logs.bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.logs.arn
  description = "ARN of the log bucket."
}
