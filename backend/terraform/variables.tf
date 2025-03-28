locals {
  config = jsondecode(file("${path.module}/variables.json"))

  project_id            = local.config.project_id
  credentials_file_path = coalesce(local.config.credentials_file_path, "credentials.json")
  location              = coalesce(local.config.location, "europe-west1")
}
