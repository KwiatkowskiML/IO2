# Service account for Cloud Run services
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "cloud_run_permissions" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/run.invoker"
  ])

  project = local.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Secret Manager access to individual secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = google_secret_manager_secret.secrets

  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Secret Manager access to the Cloud Run default compute service account as well
resource "google_secret_manager_secret_iam_member" "compute_sa_secret_access" {
  for_each = google_secret_manager_secret.secrets

  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:981338991070-compute@developer.gserviceaccount.com"
}

# Grant storage access to the service account
resource "google_project_iam_member" "cloud_run_storage_access" {
  project = local.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
