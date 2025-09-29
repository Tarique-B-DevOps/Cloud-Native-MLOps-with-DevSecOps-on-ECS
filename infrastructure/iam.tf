resource "aws_iam_role" "ecs_task_execution_role" {
  name = local.resource_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each   = toset(local.task_exec_role_policies)
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = each.value
}