# Configure terraform to store state in a Google Cloud Storage bucket
terraform {
  backend "gcs" {
    bucket = "787831b7d26887c1_bucket_tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project     = local.project_id
  region      = local.location
  credentials = file(local.credentials_file_path)
}

# Google Cloud Storage bucket to store Terraform state
resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  project       = local.project_id
  name          = "${random_id.bucket_prefix.hex}_bucket_tfstate"
  force_destroy = false
  location      = local.location

  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}

output "google_cloud_state_bucket" {
  value = google_storage_bucket.default.name
}
