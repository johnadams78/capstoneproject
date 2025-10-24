module "vpc" {
  source        = "./modules/vpc"
  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnets
  private_subnet_cidrs = var.private_subnets
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "web" {
  source        = "./modules/web"
  project_name  = var.project_name
  vpc_id        = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  private_subnets = module.vpc.private_subnet_ids
  iam_instance_profile = module.iam.ec2_instance_profile
  instance_type = var.web_instance_type
  min_size = var.web_min
  max_size = var.web_max
  allowed_cidrs = var.alb_allowed_cidrs
}

module "db" {
  source        = "./modules/db"
  project_name  = var.project_name
  vpc_id        = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  db_engine     = var.db_engine
  db_name       = var.db_name
  master_username = var.db_master_username
  master_password = var.db_master_password
  web_sg_id     = module.web.web_sg_id
}

output "alb_dns" {
  description = "Public DNS name of the ALB"
  value       = module.web.alb_dns
}

output "db_endpoint" {
  description = "Database cluster endpoint"
  value       = module.db.cluster_endpoint
}

output "web_sg_id" {
  value = module.web.web_sg_id
}

output "db_sg_id" {
  value = module.db.db_sg_id
}
