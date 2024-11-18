resource "aws_apigatewayv2_api" "website" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    allow_methods = ["GET", "HEAD", "OPTIONS"]
    allow_origins = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "website" {
  api_id = aws_apigatewayv2_api.website.id
  name   = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseTime  = "$context.responseTime"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_apigatewayv2_domain_name" "website" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "website" {
  api_id      = aws_apigatewayv2_api.website.id
  domain_name = aws_apigatewayv2_domain_name.website.id
  stage       = aws_apigatewayv2_stage.website.id
}

resource "aws_apigatewayv2_integration" "website" {
  api_id = aws_apigatewayv2_api.website.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description       = "Lambda integration"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.website.invoke_arn
}

resource "aws_apigatewayv2_route" "website" {
  api_id    = aws_apigatewayv2_api.website.id
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.website.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.website.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.website.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 30
} 