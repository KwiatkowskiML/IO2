variable "project_name" {
  type        = string
  description = "Global project identifier"
}
variable "environment" {
  type        = string
  description = "Environment name (dev|prod…)"
}
variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}
variable "db_name" {
  type        = string
  description = "Initial database name"
  default     = "authdb"
}
variable "db_username" {
  type        = string
  description = "Master username"
  default     = "resellio"
}
variable "force_db_reset" {
  type        = bool
  description = "If true, forces the db-init task to wipe the public schema before initializing. Use with caution."
  default     = false
}
