variable "project_name" { type = string }
variable "aws_region" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "alb_security_group_id" { type = string }
variable "auth_image" { type = string }
variable "ticket_image" { type = string }
variable "db_init_image" {
  type        = string
  description = "Docker image for the DB init task"
}
variable "desired_count" {
  type    = number
  default = 2
}
variable "db_endpoint" { type = string }
variable "db_password_secret_arn" { type = string }
variable "admin_secret_key_arn" {
  type        = string
  description = "ARN for the admin secret key"
}
variable "sendgrid_api_key_arn" {
  type        = string
  description = "ARN for the SendGrid API key secret"
}
variable "email_from_address" {
  type        = string
  description = "The email address to use as the sender"
}
variable "app_base_url" {
  type        = string
  description = "The base URL of the application, for constructing links in emails"
}
variable "db_user" { type = string }
variable "db_name" { type = string }
variable "db_port" {
  type    = number
  default = 5432
}
