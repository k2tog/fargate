# Creates a VPC with an internet gateway and security groups that allows http(TCP) to port 80.
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags             = merge(var.tags, map("Name", var.vpc_name))
}

# Creates private and public subnets to allow secure access to internet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet
  map_public_ip_on_launch = true
  tags       = merge(var.tags, map("Name", var.prefix))
}

# Creates a private subnet for ECS to use with awsvpc which is required for type Fargate
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet
  map_public_ip_on_launch = false
  tags       = merge(var.tags, map("Name", var.prefix))
}

# Creates internet gateway with public subnet and associated route table
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id     = aws_vpc.vpc.id
  tags       = merge(var.tags, map("Name", var.prefix))
}

resource "aws_route_table" "public_table" {
  vpc_id     = aws_vpc.vpc.id
  tags       = merge(var.tags, map("Name", var.prefix))  
}

resource "aws_route_table_association" "public_x" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
  depends_on = [aws_route_table.public_table]
}

# Creates NAT Gateway for ECS access to internet_gateway to collect docker images
resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags          = merge(var.tags, map("Name", var.prefix))
}

resource "aws_route_table" "private_table" {
  vpc_id           = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags             = merge(var.tags, map("Name", var.prefix))
}

resource "aws_route_table_association" "private_x" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_table.id
}

# Creates Security Groups that allow access to specific ports
resource "aws_security_group" "allowed" {
  name_prefix   = var.prefix
  vpc_id        = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = [var.cidr_allow_http]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.cidr_allow_ping]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags          = var.tags
}
