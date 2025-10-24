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
}

# Allow access from web security group if provided
resource "aws_security_group_rule" "allow_from_web" {
  count = length(var.web_sg_id) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.db_sg.id
  source_security_group_id = var.web_sg_id
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
    ignore_changes = [""]
  }
}

# Note: To enable Aurora Serverless v2 you may need to use provider features
# like `serverlessv2_scaling_configuration`. This scaffold leaves the cluster
# in a basic state — you can enable serverless scaling in this resource
# based on provider/version and your needs.

resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets
  tags = { Name = "${var.project_name}-db-subnet-group" }
}

output "cluster_endpoint" { value = aws_rds_cluster.aurora_cluster.endpoint }
output "db_sg_id" { value = aws_security_group.db_sg.id }
