locals {
  resource_prefix         = "${var.tags["App"]}-${var.environment}"
  task_exec_role_policies = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy", "arn:aws:iam::aws:policy/CloudWatchFullAccess"]
}