# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = local.resource_prefix
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = [
    "FARGATE"
  ]
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.resource_prefix}"
  retention_in_days = 14
}

# Task Definition
resource "aws_ecs_task_definition" "def" {
  family                   = local.resource_prefix
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  cpu                      = "1024"
  memory                   = "2048"

  container_definitions = jsonencode([
    {
      name      = local.resource_prefix
      image     = var.model_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.model_port
          hostPort      = var.model_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.resource_prefix}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      #   healthCheck = {
      #     command     = ["CMD-SHELL", "curl -f http://localhost:${var.model_port}/health || exit 1"]
      #     interval    = 30
      #     timeout     = 5
      #     retries     = 3
      #     startPeriod = 10
      #   }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = local.resource_prefix
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.def.arn
  desired_count   = 1
  launch_type     = var.launch_type

  network_configuration {
    subnets          = module.vpc.public_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = local.resource_prefix
    container_port   = var.model_port
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
  
}
