
# ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "${local.resource_prefix}-alb-sg"
  description = "Allow inbound for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow Model Port"
    from_port   = var.model_port
    to_port     = var.model_port
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