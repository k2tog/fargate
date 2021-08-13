#Creates IAM policy required by ECS Cluster using Fargate
data "aws_iam_policy_document" "ecs_tasks_service" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name                = "ecs-role"
  assume_role_policy  = data.aws_iam_policy_document.ecs_tasks_service.json
  tags                = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_role" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
