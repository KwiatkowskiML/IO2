variable "project_name" { type = string }
variable "aws_region" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "alb_security_group_id" { type = string }
variable "auth_image" { type = string }
variable "ticket_image" { type = string }
variable "desired_count" {
  type    = number
  default = 2
}
variable "db_endpoint" { type = string }
variable "db_password_secret_arn" { type = string }
variable "db_user" { type = string }
variable "db_name" { type = string }
variable "db_port" {
  type = number
  default = 5432
}
