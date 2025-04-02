output "s3_bucket" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket"
}

output "dynamodb_table" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}

output "region" {
  value       = "us-west-2"
  description = "The AWS region"
}