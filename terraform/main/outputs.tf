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

output "frontend_url" {
  description = "Public URL for the frontend application"
  value       = "https://${module.frontend_hosting.cloudfront_domain_name}"
}

output "frontend_s3_bucket_name" {
  description = "Name of the S3 bucket for the frontend files"
  value       = module.frontend_hosting.s3_bucket_name
}

output "frontend_cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for the frontend"
  value       = module.frontend_hosting.cloudfront_distribution_id
}
