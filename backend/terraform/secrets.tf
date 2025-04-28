# Generate random passwords
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_password" "secret_key" {
  length  = 32
  special = false
}

resource "random_password" "admin_secret_key" {
  length  = 32
  special = false
}

# Create secrets
locals {
  secrets = {
    "db-password" = random_password.db_password.result
    "secret-key"  = random_password.secret_key.result
    "admin-secret-key" = random_password.admin_secret_key.result

    # User Auth Service secrets
    "user-auth-db-host" = google_sql_database_instance.user_auth_db.private_ip_address
    "user-auth-db-name" = google_sql_database.user_auth_db.name

    # Event Ticketing Service secrets
    "event-ticketing-db-host" = google_sql_database_instance.event_ticketing_db.private_ip_address
    "event-ticketing-db-name" = google_sql_database.event_ticketing_db.name
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
