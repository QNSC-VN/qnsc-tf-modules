output "bucket" {
  value       = aws_s3_bucket.this.id
  description = "Bucket name."
}

output "arn" {
  value       = aws_s3_bucket.this.arn
  description = "Bucket ARN."
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "Regional domain name (for presigned URLs / origins)."
}
