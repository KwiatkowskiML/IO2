# Generate a random password for the database user
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Create a new user for the database
resource "google_sql_user" "db_user" {
  name     = "app_user"
  instance = google_sql_database_instance.ticket_db_instance.name
  password = random_password.db_password.result
}

# Configure secrets for DB connection
locals {
  secrets = {
    "db-connection-name" = google_sql_database_instance.ticket_db_instance.connection_name
    "db-name"            = google_sql_database.ticket_db.name
    "db-username"        = google_sql_user.db_user.name
    "db-password"        = random_password.db_password.result
  }
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = local.secrets
  secret_id = each.key

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each    = local.secrets
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}
