# An API Gateway REST API with no authorisation, GET method to lambda with path
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  endpoint_configuration {types = ["REGIONAL"]}
  description = "REST API to trigger lambda"
}

resource "aws_api_gateway_resource" "path" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.api_path
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.path.id
  http_method   = "GET"
  authorization = "NONE"
}

# Package the lambda function as a zip archive & provision with API GW permission
# Using source code hash so Terraform can detect changes so will re-upload the lambda function.
data "archive_file" "lambda" {
  source_file = "${path.module}/${var.function}.py"
  type        = "zip"
  output_path = "${var.function}.zip"
}

resource "aws_lambda_function" "function" {
  function_name    = var.function
  role             = var.role_arn
  handler          = "ecs_status.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  filename         = data.archive_file.lambda.output_path
  runtime          = "python3.6"
  tags             = var.tags
}

resource "aws_lambda_permission" "allow_api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowExecutionFromApiGateway"
  # source_arn    = aws_api_gateway_rest_api.api.arn
  # /*/*/* sets this permission for all stages, methods, and resource paths in API Gateway to the lambda
  # function. - https://bit.ly/2NbT5V5
  source_arn    = "${aws_api_gateway_rest_api.api.arn}/*/*/*"
  depends_on    = [ aws_api_gateway_rest_api.api ]
}

# Integrating lambda with API Gateway and permissions to invoke the function 
resource "aws_api_gateway_integration" "lambda_x" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.path.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_integration_response" "response_x" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.path.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response.status_code
  depends_on  = [ aws_api_gateway_integration.lambda_x ]
}

resource "aws_api_gateway_method_response" "response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.path.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.prefix
  depends_on  = [
    aws_api_gateway_integration.lambda_x,
    aws_api_gateway_integration_response.response_x
  ]
}
