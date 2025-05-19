# === variables.tf ===

variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "eu-west-3" 
}
