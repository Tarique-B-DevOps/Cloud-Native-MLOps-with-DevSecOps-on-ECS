resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.resource_prefix}-api"
  protocol_type = "HTTP"
}

# Create integration per route with explicit ALB path
resource "aws_apigatewayv2_integration" "alb_integrations" {
  for_each = var.api_routes

  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = each.value.method
  integration_uri        = "http://${aws_lb.alb.dns_name}${each.value.path}"
  payload_format_version = "1.0"
}

# Create routes pointing to the corresponding integration
resource "aws_apigatewayv2_route" "routes" {
  for_each = var.api_routes

  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integrations[each.key].id}"
}

# Stage
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.environment
  auto_deploy = true
}
