output "api_gateway_url" {
  value = google_cloud_run_service.api_gateway.status[0].url
}

output "user_auth_service_url" {
  value = google_cloud_run_service.user_auth_service.status[0].url
}

output "event_ticketing_service_url" {
  value = google_cloud_run_service.event_ticketing_service.status[0].url
}

output "user_auth_db_instance_name" {
  value = google_sql_database_instance.user_auth_db.name
}

output "event_ticketing_db_instance_name" {
  value = google_sql_database_instance.event_ticketing_db.name
}
