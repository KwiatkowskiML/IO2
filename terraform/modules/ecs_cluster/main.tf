data "aws_subnet" "first_public" { id = var.public_subnet_ids[0] }
data "aws_vpc" "this" { id = data.aws_subnet.first_public.vpc_id }

# ECS cluster & IAM
resource "aws_ecs_cluster" "this" { name = "${var.project_name}-cluster" }

#
# Task Level IAM
#

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "task_secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "kms:Decrypt"
    ]
    resources = [var.db_password_secret_arn]
  }
}

resource "aws_iam_role" "task_exec" {
  name               = "${var.project_name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "task_secrets_access_policy" {
  name = "${var.project_name}-ecsTaskSecretsAccessPolicy"
  description = "Allows ECS tasks to access secrets"
  policy = data.aws_iam_policy_document.task_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "task_role_secrets_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_secrets_access_policy.arn
}

# Load balancer
resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]
}

resource "aws_lb_target_group" "auth" {
  name        = "${var.project_name}-tg-auth"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id
  health_check { path = "/health" }
}

resource "aws_lb_target_group" "tickets" {
  name        = "${var.project_name}-tg-tickets"
  port        = 8001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id
  health_check { path = "/health" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
      message_body = "Not found"
    }
  }
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }
  condition {
    path_pattern {
      values = ["/api/auth/*", "/api/user/*"]
    }
  }
}

resource "aws_lb_listener_rule" "tickets" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tickets.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Logs
resource "aws_cloudwatch_log_group" "lg" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 14
}

locals {
  common_env = [
    {
      name  = "DB_URL"
      value = var.db_endpoint
    },
    {
      name  = "DB_PASSWORD_SECRET_ARN"
      value = var.db_password_secret_arn
    },
    {
      name  = "DB_USER"
      value = var.db_user
    },
    {
      name  = "DB_NAME"
      value = var.db_name
    },
    {
      name  = "DB_PORT"
      value = tostring(var.db_port)
    },
    {
      name = "AWS_REGION"
      value = var.aws_region
    }
  ]
}

# Task definitions
resource "aws_ecs_task_definition" "auth" {
  family                   = "${var.project_name}-auth"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = "auth"
      image = var.auth_image
      portMappings = [
        { containerPort = 8000
          hostPort      = 8000
        protocol = "tcp" }
      ]
      environment = local.common_env
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.lg.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "auth"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "tickets" {
  family                   = "${var.project_name}-tickets"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = "tickets"
      image = var.ticket_image
      portMappings = [
        { containerPort = 8001
          hostPort      = 8001
          protocol      = "tcp"
        }
      ]
      environment = local.common_env
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.lg.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "tickets"
        }
      }
    }
  ])
}

# Services
resource "aws_ecs_service" "auth" {
  name            = "${var.project_name}-auth"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name   = "auth"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener_rule.auth]
}

resource "aws_ecs_service" "tickets" {
  name            = "${var.project_name}-tickets"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.tickets.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tickets.arn
    container_name   = "tickets"
    container_port   = 8001
  }

  depends_on = [aws_lb_listener_rule.tickets]
}
