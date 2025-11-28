variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "db_engine" { type = string }
variable "db_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }

variable "db_serverless" {
	description = "Enable serverless-style autoscaling for the DB (if supported)"
	type        = bool
	default     = true
}

variable "db_min_capacity" {
	type    = number
	default = 1
}

variable "db_max_capacity" {
	type    = number
	default = 2
}
