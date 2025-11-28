variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "iam_instance_profile" { type = string }
variable "instance_type" { type = string }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "allowed_cidrs" { type = list(string) }

variable "db_endpoint" {
  description = "Database endpoint for the web application"
  type        = string
}

variable "db_password" {
  description = "Database password for the web application"
  type        = string
  sensitive   = true
}
