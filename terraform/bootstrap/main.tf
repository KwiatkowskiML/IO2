provider "aws" {
  region = local.region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_bucket_encryption" {
  bucket = aws_s3_bucket.tfstate_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

resource "aws_s3_bucket_versioning" "tfstate_bucket_versioning" {
  bucket = aws_s3_bucket.tfstate_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = local.s3_bucket_name

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = false
  }

}

resource "local_file" "backend_config_output" {
  content = jsonencode({
    bucket         = aws_s3_bucket.tfstate_bucket.bucket
    dynamodb_table = aws_dynamodb_table.tfstate_lock.name
    key            = local.state_file_path
    encrypt        = true
    region         = local.region
  })
  filename = local.backend_config_path

  depends_on = [
    aws_s3_bucket.tfstate_bucket,
    aws_dynamodb_table.tfstate_lock,
    aws_s3_bucket_server_side_encryption_configuration.tfstate_bucket_encryption,
    aws_s3_bucket_versioning.tfstate_bucket_versioning,
  ]
}
