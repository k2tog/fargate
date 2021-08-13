variable "prefix" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "private_subnet" {}
variable "public_subnet" {}
variable "cidr_allow_http" {default = "0.0.0.0/0"}
variable "cidr_allow_ping" {default = "10.0.0.0/24"}
variable "tags" {type = map(string)}