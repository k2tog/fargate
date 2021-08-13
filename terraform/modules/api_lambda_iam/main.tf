#Creates IAM policy required by ECS Cluster using Fargate
data "aws_iam_policy_document" "lambda_service" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_lambda_role" {
  name                = "api-lambda-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_service.json
  tags                = var.tags
}

resource "aws_iam_role_policy_attachment" "api_lambda_role" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ecs_role" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
