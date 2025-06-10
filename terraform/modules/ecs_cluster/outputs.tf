output "alb_dns_name" { value = aws_lb.this.dns_name }
output "ecs_cluster_arn" {
  description = "ARN of the ECS Cluster"
  value       = aws_ecs_cluster.this.arn
}
output "db_init_task_definition_arn" {
  description = "ARN of the DB Init Task Definition"
  value       = aws_ecs_task_definition.db_init.arn
}
