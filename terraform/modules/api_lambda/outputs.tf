# URL to invoke the API
output "url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
