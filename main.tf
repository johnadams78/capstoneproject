# VPC Module (Always deployed - foundation)
module "vpc" {
  source        = "./modules/vpc"
  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnets
  private_subnet_cidrs = var.private_subnets
}

# IAM Module (Always deployed - needed for EC2 instances)
module "iam" {
  source = "./modules/iam"
}

# Database Module (Conditional)
module "db" {
  count = var.deploy_database ? 1 : 0
  source = "./modules/db"

  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  db_engine       = "aurora-mysql"
  db_name         = "capstonedb"
  master_username = "admin"
  master_password = var.db_master_password
}

# Web Module (Conditional)
module "web" {
  count = var.deploy_web ? 1 : 0
  source = "./modules/web"

  project_name         = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnet_ids
  private_subnets     = module.vpc.private_subnet_ids
  instance_type       = var.instance_type
  key_name           = var.key_name
  iam_instance_profile = module.iam.ec2_instance_profile_name
  
  # Database connection (if database is deployed)
  db_endpoint = var.deploy_database ? module.db[0].aurora_cluster_endpoint : ""
  db_name     = var.deploy_database ? "capstonedb" : ""
  db_username = var.deploy_database ? "admin" : ""
  db_password = var.deploy_database ? var.db_master_password : ""
}

# Monitoring Module (Conditional)
module "monitoring" {
  count = var.deploy_monitoring ? 1 : 0
  source = "./modules/monitoring"

  project_name         = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnet_ids
  instance_type       = var.instance_type
  key_name           = var.key_name
  iam_instance_profile = module.iam.ec2_instance_profile_name
}