locals {
  s3_bucket_name        = "tfstate-${random_string.suffix.result}"
  dynamodb_table_name   = "tfstate-lock-${random_string.suffix.result}"
  region                = var.region
  state_file_path       = "terraform.tfstate"
  backend_config_path   = "${path.module}/../main/backend_config.json"
}

