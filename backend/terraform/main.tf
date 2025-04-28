# Provider configuration
provider "google" {
  project     = local.project_id
  region      = local.location
  credentials = file(local.credentials_file_path)
}

provider "google-beta" {
  project     = local.project_id
  region      = local.location
  credentials = file(local.credentials_file_path)
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "containerregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com"
  ])

  service            = each.value
  disable_on_destroy = false

  timeouts {
    create = "30m"
    update = "40m"
  }
}
