
# ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "${local.resource_prefix}-alb-sg"
  description = "Allow inbound for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Service SG
resource "aws_security_group" "ecs_sg" {
  name        = "${local.resource_prefix}-ecs-sg"
  description = "Allow inbound from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.model_port
    to_port         = var.model_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
