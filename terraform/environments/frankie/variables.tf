variable "credentials_path" {default = "/Users/mssha/.aws/creds"}

variable "prefix" {default = "k2tog"}
variable "region" {default = "ap-southeat-2"}

variable "vpc_name" {default = "k2tog_frankie"}
variable "vpc_cidr" {default = "192.168.0.0/16"}
variable "public_subnet_cidr"  {default = "192.168.1.0/24"}
variable "private_subnet_cidr" {default = "192.168.2.0/24"}

variable "service_tags" {
  type = map(string)
  default = {
    "owner" = "K2"
    "environment" = "batcave"
    "contact" = "batphone"
  }
}

variable "ecs_cluster_name" {default = "k2tog_cluster"}
variable "ecs_task_image"   {default = "hello"}
variable "ecs_task_count"   {default = 1}
variable "ecs_task_cpu"     {default = "256"}
variable "ecs_task_memory"  {default = "1024"}

variable "lambda_name"      {default = "ecs_status"}
variable "api_gateway_name" {default = "frankie"}
variable "api_path"         {default = "list"}
