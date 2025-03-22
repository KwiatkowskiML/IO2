# Cloud SQL instance for PostgreSQL
resource "google_sql_database_instance" "ticket_db_instance" {
  name             = "ticket-db-instance"
  database_version = "POSTGRES_13"
  region           = local.location

  settings {
    tier = "db-f1-micro"
  }
}

# Database
resource "google_sql_database" "ticket_db" {
  name     = "ticket-db"
  instance = google_sql_database_instance.ticket_db_instance.name
}
