resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.project_name}-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = var.engine_version
  database_name           = var.db_name
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids
  backup_retention_period = 7
  skip_final_snapshot     = true
  tags                    = { Name = "${var.project_name}-aurora-cluster" }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier          = "${var.project_name}-aurora-writer"
  cluster_identifier  = aws_rds_cluster.this.id
  instance_class      = var.instance_class
  engine              = aws_rds_cluster.this.engine
  engine_version      = aws_rds_cluster.this.engine_version
  publicly_accessible = false
  tags                = { Name = "${var.project_name}-aurora-writer" }
}
