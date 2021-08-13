#Creates an ECS Fargate Cluster with launch configuration
resource "aws_ecs_cluster" "ecs_cluster" {
  name  = var.name
  tags  = var.tags
}

data "template_file" "task_definition_template" {
  template = file("${path.module}/${var.image}.json")
  vars = {}
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.prefix
  task_role_arn            = var.role_arn
  execution_role_arn       = var.role_arn
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.task_definition_template.rendered
  tags                     = var.tags
}

resource "aws_ecs_service" "service" {
  name            = var.prefix
  cluster         = aws_ecs_cluster.ecs_cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.desired
  network_configuration {
    subnets          = [var.subnet]
    assign_public_ip = true
  }
}