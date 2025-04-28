locals {
  config = jsondecode(file("${path.module}/variables.json"))
  project_id            = local.config.project_id
  credentials_file_path = coalesce(local.config.credentials_file_path, "credentials.json")
  location              = coalesce(local.config.location, "europe-west1")

  # Service configurations
  services = {
    user_auth_service = {
      name = "user-auth-service"
      port = 8000
      image = "user-auth-service"
    }
    event_ticketing_service = {
      name = "event-ticketing-service"
      port = 8001
      image = "event-ticketing-service"
    }
    api_gateway = {
      name = "api-gateway"
      port = 8080
      image = "api-gateway"
    }
  }
}
