output "tfstate_s3_bucket_name" {
  description = "The name of the S3 bucket created for Terraform state."
  value       = aws_s3_bucket.tfstate_bucket.bucket
}

output "tfstate_dynamodb_table_name" {
  description = "The name of the DynamoDB table created for Terraform state locking."
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "backend_config_file_path" {
  description = "Path to the generated backend configuration file."
  value       = local_file.backend_config_output.filename
}
