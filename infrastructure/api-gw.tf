resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.resource_prefix}-api"
  protocol_type = "HTTP"
}

# Integration with ALB (no proxy)
resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${aws_lb.alb.dns_name}"
  payload_format_version = "1.0"
}

# Explicit routes from map variable
resource "aws_apigatewayv2_route" "routes" {
  for_each  = var.api_routes
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.environment
  auto_deploy = true
}
