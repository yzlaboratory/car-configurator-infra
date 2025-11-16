##TODO
# Sidecars
# Logs to stdout and stderror
# role for rds zugriff for 1 task

# --- 1. ECS Cluster ---
resource "aws_ecs_cluster" "staging" {
  name = "${var.project_name}-cluster"
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "catalog" {
  name        = "${var.project_name}-1"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Erforderlich für Fargate

  health_check {
    path = "/actuator/health"
  }
}

resource "aws_lb_target_group" "orders" {
  name        = "${var.project_name}-3"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Erforderlich für Fargate

  health_check {
    path = "/actuator/health"
  }
}

resource "aws_lb_target_group" "config" {
  name        = "${var.project_name}-2"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Erforderlich für Fargate

  health_check {
    path = "/actuator/health"
  }
}

resource "aws_lb_listener_rule" "config_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config.arn
  }

  condition {
    path_pattern {
      values = ["/configs/*"]
    }
  }
}

resource "aws_lb_listener_rule" "catalog_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalog.arn
  }

  condition {
    path_pattern {
      values = ["/catalog/*"]
    }
  }
}
resource "aws_lb_listener_rule" "orders_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orders.arn
  }

  condition {
    path_pattern {
      values = ["/orders/*"]
    }
  }
}
# --- 3. ECS Task Definition (Fargate) ---
resource "aws_ecs_task_definition" "catalog" {
  family                   = "${var.project_name}-catalog-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 0.25 vCPU
  memory                   = 512 # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-api-catalog"
      image     = var.container_image_catalog
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      "environment" : [
        {
          "name" : "AWS_REGION",
          "value" : var.aws_region
        },
        {
          "name" : "DYNAMODB_TABLE_NAME",
          "value" : aws_dynamodb_table.catalog_table.name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.project_name
        }
      },
      "healthCheck" : {
        # This command is run inside the container.
        # It must exit 0 for success or 1 for failure.
        # This example pings a health endpoint.
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}/actuator/health || exit 1"
        ],
        "interval" : 30,   # Time between checks (in seconds)
        "timeout" : 5,     # Time to wait for a response
        "retries" : 3,     # How many failures before marking as unhealthy
        "startPeriod" : 60 # Grace period to allow the container to start
      }
    }
  ])
}

resource "aws_ecs_task_definition" "orders" {
  family                   = "${var.project_name}-orders-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 0.25 vCPU
  memory                   = 512 # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-api-orders"
      image     = var.container_image_orders
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.project_name
        }
      }

      "healthCheck" : {
        # This command is run inside the container.
        # It must exit 0 for success or 1 for failure.
        # This example pings a health endpoint.
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}/actuator/health || exit 1"
        ],
        "interval" : 30,   # Time between checks (in seconds)
        "timeout" : 5,     # Time to wait for a response
        "retries" : 3,     # How many failures before marking as unhealthy
        "startPeriod" : 60 # Grace period to allow the container to start
      }
    }
  ])
}

resource "aws_ecs_task_definition" "configs" {
  family                   = "${var.project_name}-configs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 0.25 vCPU
  memory                   = 512 # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Für DynamoDB-Zugriff

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-api-configs"
      image     = var.container_image_configs
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.project_name
        }
      }
      "environment" : [
        {
          "name" : "AWS_REGION",
          "value" : var.aws_region
        },
        {
          "name" : "DYNAMODB_TABLE_NAME",
          "value" : aws_dynamodb_table.configs_table.name
        }
      ]
      "healthCheck" : {
        # This command is run inside the container.
        # It must exit 0 for success or 1 for failure.
        # This example pings a health endpoint.
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}/actuator/health || exit 1"
        ],
        "interval" : 30,   # Time between checks (in seconds)
        "timeout" : 5,     # Time to wait for a response
        "retries" : 3,     # How many failures before marking as unhealthy
        "startPeriod" : 60 # Grace period to allow the container to start
      }
    }
  ])
}

# Log-Gruppe für den Container
resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/${var.project_name}"
}

# --- 4. ECS Service ---
# Dieser Service sorgt dafür, dass der Task läuft und verbindet ihn mit dem ALB
resource "aws_ecs_service" "orders" {
  name            = "${var.project_name}-orders-ecs"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.orders.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.orders.arn
    container_name   = "${var.project_name}-api-orders"
    container_port   = var.container_port
  }

  # Stellt sicher, dass der ALB vorhanden ist, bevor der Service startet
  depends_on = [aws_lb_listener.http]
}

# --- 4. ECS Service ---
# Dieser Service sorgt dafür, dass der Task läuft und verbindet ihn mit dem ALB
resource "aws_ecs_service" "catalog" {
  name            = "${var.project_name}-catalog-ecs"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.catalog.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.catalog.arn
    container_name   = "${var.project_name}-api-catalog"
    container_port   = var.container_port
  }

  # Stellt sicher, dass der ALB vorhanden ist, bevor der Service startet
  depends_on = [aws_lb_listener.http]
}

# --- 4. ECS Service ---
# Dieser Service sorgt dafür, dass der Task läuft und verbindet ihn mit dem ALB
resource "aws_ecs_service" "configs" {
  name            = "${var.project_name}-configs-ecs"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.configs.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.config.arn
    container_name   = "${var.project_name}-api-configs"
    container_port   = var.container_port
  }

  # Stellt sicher, dass der ALB vorhanden ist, bevor der Service startet
  depends_on = [aws_lb_listener.http]
}

