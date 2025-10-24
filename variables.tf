variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "lifesci-app"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24","10.0.1.0/24"]
}

variable "private_subnets" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24","10.0.11.0/24"]
}

variable "web_min" { type = number, default = 2 }
variable "web_max" { type = number, default = 3 }

variable "web_instance_type" {
  description = "EC2 instance type for web servers (keep minimal CPU/mem)"
  type        = string
  default     = "t3.micro"
}

variable "alb_allowed_cidrs" {
  description = "CIDRs allowed to access ALB (HTTP/HTTPS)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_engine" {
  description = "Database engine for Aurora cluster"
  type        = string
  default     = "aurora-mysql"
}

variable "db_name" { type = string, default = "lifesci" }

variable "db_master_username" { type = string, default = "dbadmin" }

variable "db_master_password" {
  type        = string
  description = "Master DB password (override in terraform.tfvars or Secrets Manager)"
  default     = "ChangeMe123!"
  sensitive   = true
}
