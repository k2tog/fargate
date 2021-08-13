output "id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.private_subnet.id
}