# ECS Fargate + ALB + ECR para la API FastAPI (Fase 5).
# Learner Lab: LabRole como execution role y task role (sin iam:CreateRole).

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name        = "${var.project_name}-api-ecr-${var.environment}"
    Environment = var.environment
  }
}

resource "null_resource" "api_docker_push" {
  triggers = {
    dockerfile = filemd5("${path.module}/../../../api/Dockerfile")
    reqs       = filemd5("${path.module}/../../../api/requirements.txt")
    main_py    = filemd5("${path.module}/../../../api/app/main.py")
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/scripts/push_api_image.sh ${aws_ecr_repository.api.repository_url} ${var.aws_region}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_ecr_repository.api]
}

# --- Application Load Balancer ---

resource "aws_lb" "api" {
  name               = "${var.project_name}-api-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups      = [var.alb_security_group_id]
  subnets            = var.ecs_subnet_ids

  tags = {
    Name = "${var.project_name}-api-alb-${var.environment}"
  }
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project_name}-api-tg-${var.environment}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-api-tg-${var.environment}"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# --- ECS ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  tags = {
    Name = "${var.project_name}-ecs-${var.environment}"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-api-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${aws_ecr_repository.api.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "DYNAMODB_TABLE_NAME", value = var.dynamodb_table_name },
        { name = "MONGODB_URI", value = local.mongodb_uri },
        { name = "MONGODB_DATABASE", value = var.mongodb_database },
        { name = "MONGODB_SENSORS_COLLECTION", value = "sensors" },
        { name = "MONGODB_EVENTS_COLLECTION", value = var.mongodb_events_collection },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])

  depends_on = [null_resource.api_docker_push]

  tags = {
    Name = "${var.project_name}-api-task-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}-api-${var.environment}"
  retention_in_days = 7
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.http,
    null_resource.api_docker_push,
    aws_instance.mongodb,
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
