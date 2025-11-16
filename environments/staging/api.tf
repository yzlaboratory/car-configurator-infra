# Wir verwenden ein HTTP API Gateway (v2), da es schneller und billiger ist.
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id
  integration_uri    = aws_lb_listener.http.arn
  request_parameters = {
    # Ersetzt den gesamten Pfad der ausgehenden Anfrage
    "overwrite:path" = "/$request.path.proxy"
  }
}

# Route: Leitet alle Anfragen (ANY /...) an die Integration weiter
resource "aws_apigatewayv2_route" "catalog" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Stage: Stellt die API bereit (z.B. unter /dev oder /v1)
# $default stellt automatisch bereit
resource "aws_apigatewayv2_stage" "staging" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.project_name}-vpc-link"
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.alb.id]
}