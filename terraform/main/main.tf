# Network
module "network" {
  source               = "../modules/network"
  project_name         = var.project_name
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = true
}

# Secrets
resource "random_password" "db_master_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_master_password" {
  name = "${var.project_name}-db-master-password"
}

resource "aws_secretsmanager_secret_version" "db_master_password" {
  secret_id     = aws_secretsmanager_secret.db_master_password.id
  secret_string = random_password.db_master_password.result
}

# Database
module "db" {
  source                 = "../modules/rds"
  project_name           = var.project_name
  aws_region             = var.aws_region
  db_name                = var.db_name
  master_username        = var.db_username
  master_password        = random_password.db_master_password.result
  db_subnet_ids          = module.network.private_subnet_ids
  vpc_security_group_ids = [module.network.rds_security_group_id]
}

# ECS & Load Balancer
module "ecs_cluster" {
  source                 = "../modules/ecs_cluster"
  project_name           = var.project_name
  aws_region             = var.aws_region
  public_subnet_ids      = module.network.public_subnet_ids
  private_subnet_ids     = module.network.private_subnet_ids
  ecs_security_group_id  = module.network.ecs_security_group_id
  alb_security_group_id  = module.network.alb_security_group_id
  db_endpoint            = module.db.endpoint
  db_password_secret_arn = aws_secretsmanager_secret.db_master_password.arn
  auth_image             = var.auth_image
  ticket_image           = var.ticket_image
  db_user                = var.db_username
  db_name                = var.db_name
}
