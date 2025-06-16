variable "project_name" {
  type        = string
  description = "Global project identifier"
}

variable "api_base_url" {
  type        = string
  description = "The DNS name of the backend Application Load Balancer, used to route API requests."
}
