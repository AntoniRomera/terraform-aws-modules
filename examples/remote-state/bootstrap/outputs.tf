output "bucket_name" {
  description = "Name of the S3 state bucket. Use as backend `bucket`."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the S3 state bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB lock table. Use as backend `dynamodb_table`."
  value       = aws_dynamodb_table.lock.name
}

output "region" {
  description = "Region the backend resources live in. Use as backend `region`."
  value       = var.region
}
