module "vpc" {
  source        = "./modules/vpc"
  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnets
  private_subnet_cidrs = var.private_subnets
}

module "db" {
  source = "./modules/db"

  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  db_engine       = "aurora-mysql"
  db_name         = "capstonedb"
  master_username = "admin"
  master_password = "CapstoneDB2024!"
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
  instance_type   = var.instance_type
}