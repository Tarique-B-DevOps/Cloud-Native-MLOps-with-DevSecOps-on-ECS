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

# Task Definition
resource "aws_ecs_task_definition" "def" {
  family                   = local.resource_prefix
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
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
    }
  ])
}