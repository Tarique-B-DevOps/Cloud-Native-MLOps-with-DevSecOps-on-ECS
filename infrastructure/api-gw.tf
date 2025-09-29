resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.resource_prefix}-api"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${aws_lb.alb.dns_name}"
  payload_format_version = "1.0"
}


resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}" # catches all paths
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

resource "aws_apigatewayv2_stage" "staging" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "staging"
  auto_deploy = true
}
