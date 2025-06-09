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

resource "random_string" "admin_secret_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "admin_secret_key" {
  name = "${var.project_name}-admin-secret-key"
}

resource "aws_secretsmanager_secret_version" "admin_secret_key" {
  secret_id     = aws_secretsmanager_secret.admin_secret_key.id
  secret_string = random_string.admin_secret_key.result
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

# Data Sources to look up ECR repositories created by the build script
data "aws_ecr_repository" "auth" {
  name = "${var.project_name}-auth"
}

data "aws_ecr_repository" "tickets" {
  name = "${var.project_name}-tickets"
}

data "aws_ecr_repository" "db_init" {
  name = "${var.project_name}-db-init"
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
  admin_secret_key_arn   = aws_secretsmanager_secret.admin_secret_key.arn
  auth_image             = "${data.aws_ecr_repository.auth.repository_url}:latest"
  ticket_image           = "${data.aws_ecr_repository.tickets.repository_url}:latest"
  db_init_image          = "${data.aws_ecr_repository.db_init.repository_url}:latest"
  db_user                = var.db_username
  db_name                = var.db_name
}

# One-off task to initialize the database schema
resource "null_resource" "db_initializer" {
  triggers = {
    db_endpoint    = module.db.endpoint
    task_def_arn   = module.ecs_cluster.db_init_task_definition_arn
    force_db_reset = var.force_db_reset
  }

  depends_on = [
    module.db,
    module.ecs_cluster,
    data.aws_ecr_repository.db_init
  ]

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      NETWORK_CONFIG=$(cat <<EOF
      {
          "awsvpcConfiguration": {
              "subnets": ${jsonencode(module.network.private_subnet_ids)},
              "securityGroups": ["${module.network.ecs_security_group_id}"],
              "assignPublicIp": "DISABLED"
          }
      }
      EOF
      )

      OVERRIDES_CONFIG="{}" # Default to an empty JSON object
      if ${var.force_db_reset}; then
        echo "DB reset is enabled. Preparing container overrides to set DB_RESET=true..."
        OVERRIDES_CONFIG='{
          "containerOverrides": [
            {
              "name": "db-init",
              "environment": [
                {
                  "name": "DB_RESET",
                  "value": "true"
                }
              ]
            }
          ]
        }'
      else
        echo "DB reset is not enabled. Running task without overrides."
      fi

      echo "Running DB init task..."
      TASK_ARN=$(aws ecs run-task \
        --cluster ${module.ecs_cluster.ecs_cluster_arn} \
        --task-definition ${self.triggers.task_def_arn} \
        --launch-type FARGATE \
        --network-configuration "$NETWORK_CONFIG" \
        --overrides "$OVERRIDES_CONFIG" \
        --region ${var.aws_region} \
        --query 'tasks[0].taskArn' \
        --output text)
      
      echo "Waiting for DB init task ($TASK_ARN) to complete..."
      
      aws ecs wait tasks-stopped \
        --cluster ${module.ecs_cluster.ecs_cluster_arn} \
        --tasks $TASK_ARN \
        --region ${var.aws_region}
        
      echo "DB init task finished."
    EOT
  }
}
