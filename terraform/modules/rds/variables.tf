variable "project_name" {
  description = "Global project identifier (passed from root module)"
  type        = string
}

variable "aws_region" {
  description = "AWS region (optional in this module, but kept for consistency)"
  type        = string
}

variable "db_name" {
  description = "Initial database name created inside the cluster"
  type        = string
}

variable "master_username" {
  description = "Master (admin) username for the database cluster"
  type        = string
}

variable "master_password" {
  description = "Master (admin) password – marked sensitive so it never appears in logs"
  type        = string
  sensitive   = true
}

variable "db_subnet_ids" {
  description = "List of private subnet IDs where the cluster will be placed"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups that control access to the cluster"
  type        = list(string)
}
variable "engine_version" {
  description = "Aurora‑PostgreSQL engine version"
  type        = string
  default     = "15.10"
}

variable "instance_class" {
  description = "Instance class for writer/reader nodes (override for production)"
  type        = string
  default     = "db.t4g.medium"
}
