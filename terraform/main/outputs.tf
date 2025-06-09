output "alb_dns_name" {
  description = "DNS name of the public load balancer"
  value       = module.ecs_cluster.alb_dns_name
}

output "api_base_url" {
  description = "Base URL for sending requests"
  value       = "http://${module.ecs_cluster.alb_dns_name}"
}

output "db_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = module.db.endpoint
}

output "project_name" {
  description = "The project name used for all resources"
  value       = var.project_name
}
