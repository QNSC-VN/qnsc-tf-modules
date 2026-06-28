output "lambda_function_arn" {
  value       = aws_lambda_function.this.arn
  description = "ARN of the scheduler Lambda."
}

output "lambda_function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Name of the scheduler Lambda (for manual invoke / logs)."
}
