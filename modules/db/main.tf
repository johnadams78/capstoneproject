resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow DB access from web tier"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# Aurora Serverless v2 cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "${var.project_name}-cluster"
  engine             = var.db_engine
  database_name      = var.db_name
  master_username    = var.master_username
  master_password    = var.master_password
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  skip_final_snapshot = true

  # If serverless flag is set, configure engine mode and scaling config
  lifecycle {
    ignore_changes = []
  }
}

# Aurora cluster instance
resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = 1
  identifier         = "${var.project_name}-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets
  tags = { Name = "${var.project_name}-db-subnet-group" }
}

output "cluster_endpoint" { value = aws_rds_cluster.aurora_cluster.endpoint }
output "db_sg_id" { value = aws_security_group.db_sg.id }
