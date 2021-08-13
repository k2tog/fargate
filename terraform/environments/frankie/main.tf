# Configure the AWS Provider
provider "aws" {
  version = "~> 3.0"
  region  = "ap-southeast-2"
  shared_credentials_file = var.credentials_path
}

# Create a VPC, Internet Gateway with public facing subnet 
# and Security Group with http ingres to port 80
module "aws_vpc_network" {
  source         = "../../modules/network"
  prefix         = var.prefix
  vpc_name       = var.vpc_name
  vpc_cidr       = var.vpc_cidr
  private_subnet = var.private_subnet_cidr
  public_subnet  = var.public_subnet_cidr
  tags           = var.service_tags
}

# Create an ECS cluster with service running single task running container
# IAM kept seperate for future move to consolidated IAM location
module "aws_ecs_iam" {
  source   = "../../modules/ecs_iam"
  tags     = var.service_tags
}
module "aws_ecs_cluster" {
  source   = "../../modules/ecs"
  prefix   = var.prefix
  name     = var.ecs_cluster_name
  image    = var.ecs_task_image
  desired  = var.ecs_task_count
  role_arn = module.aws_ecs_iam.arn
  cpu      = var.ecs_task_cpu
  memory   = var.ecs_task_memory
  subnet   = module.aws_vpc_network.public_subnet_id
  tags     = var.service_tags
}

# Create integrated Lambda function and API Gateway with GET method to required URI path
# IAM kept seperate for future move to consolidated IAM location
module "aws_lambda_iam" {
  source     = "../../modules/api_lambda_iam"
  tags     = var.service_tags
}
module "aws_api_call_lambda" {
  source     = "../../modules/api_lambda"
  prefix     = var.prefix
  region     = var.region
  api_name   = var.api_gateway_name
  api_path   = var.api_path
  function   = var.lambda_name
  role_arn   = module.aws_lambda_iam.arn
  tags       = var.service_tags
}
