# User Auth Database
resource "google_sql_database_instance" "user_auth_db" {
  name             = "user-auth-db-instance"
  database_version = "POSTGRES_13"
  region           = local.location

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc_network.id
    }
  }

  deletion_protection = false  # Set to true in production

  depends_on = [google_project_service.required_apis, google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "user_auth_db" {
  name     = "resellio_db"
  instance = google_sql_database_instance.user_auth_db.name
}

# Event Ticketing Database
resource "google_sql_database_instance" "event_ticketing_db" {
  name             = "event-ticketing-db-instance"
  database_version = "POSTGRES_13"
  region           = local.location

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc_network.id
    }
  }

  deletion_protection = false  # Set to true in production

  depends_on = [google_project_service.required_apis, google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "event_ticketing_db" {
  name     = "resellio_event_ticketing_db"
  instance = google_sql_database_instance.event_ticketing_db.name
}

# Database Users
resource "google_sql_user" "user_auth_db_user" {
  name     = "root"
  instance = google_sql_database_instance.user_auth_db.name
  password = random_password.db_password.result
}

resource "google_sql_user" "event_ticketing_db_user" {
  name     = "root"
  instance = google_sql_database_instance.event_ticketing_db.name
  password = random_password.db_password.result
}
