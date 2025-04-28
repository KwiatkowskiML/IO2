# Cloud Run Services

# User Auth Service
resource "google_cloud_run_service" "user_auth_service" {
  name     = local.services.user_auth_service.name
  location = local.location

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email

      containers {
        image = "gcr.io/${local.project_id}/${local.services.user_auth_service.image}"

        ports {
          container_port = local.services.user_auth_service.port
        }

        env {
          name  = "POSTGRES_USER"
          value = "root"
        }

        env {
          name = "POSTGRES_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["db-password"].secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "POSTGRES_DB"
          value = google_sql_database.user_auth_db.name
        }

        env {
          name = "POSTGRES_HOST"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["user-auth-db-host"].secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "POSTGRES_PORT"
          value = "5432"
        }

        env {
          name = "SECRET_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["secret-key"].secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "ACCESS_TOKEN_EXPIRE_MINUTES"
          value = "30"
        }

        env {
          name = "ADMIN_SECRET_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["admin-secret-key"].secret_id
              key  = "latest"
            }
          }
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_sql_database.user_auth_db]
}

# Event Ticketing Service
resource "google_cloud_run_service" "event_ticketing_service" {
  name     = local.services.event_ticketing_service.name
  location = local.location

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email

      containers {
        image = "gcr.io/${local.project_id}/${local.services.event_ticketing_service.image}"

        ports {
          container_port = local.services.event_ticketing_service.port
        }

        env {
          name  = "POSTGRES_USER"
          value = "root"
        }

        env {
          name = "POSTGRES_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["db-password"].secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "POSTGRES_DB"
          value = google_sql_database.event_ticketing_db.name
        }

        env {
          name = "POSTGRES_HOST"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["event-ticketing-db-host"].secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "POSTGRES_PORT"
          value = "5432"
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_sql_database.event_ticketing_db]
}

# API Gateway Service
resource "google_cloud_run_service" "api_gateway" {
  name     = local.services.api_gateway.name
  location = local.location

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email

      containers {
        image = "gcr.io/${local.project_id}/${local.services.api_gateway.image}"

        ports {
          container_port = local.services.api_gateway.port
        }

        env {
          name  = "USER_AUTH_SERVICE_URL"
          value = google_cloud_run_service.user_auth_service.status[0].url
        }

        env {
          name  = "EVENT_TICKETING_SERVICE_URL"
          value = google_cloud_run_service.event_ticketing_service.status[0].url
        }

        env {
          name = "SECRET_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secrets["secret-key"].secret_id
              key  = "latest"
            }
          }
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_cloud_run_service.user_auth_service,
    google_cloud_run_service.event_ticketing_service
  ]
}

# IAM policies for services
resource "google_cloud_run_service_iam_member" "api_gateway_public" {
  service  = google_cloud_run_service.api_gateway.name
  location = google_cloud_run_service.api_gateway.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow API Gateway to invoke backend services
resource "google_cloud_run_service_iam_member" "user_auth_service_invoker" {
  service  = google_cloud_run_service.user_auth_service.name
  location = google_cloud_run_service.user_auth_service.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_service_iam_member" "event_ticketing_service_invoker" {
  service  = google_cloud_run_service.event_ticketing_service.name
  location = google_cloud_run_service.event_ticketing_service.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
