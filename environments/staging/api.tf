# Wir verwenden ein HTTP API Gateway (v2), da es schneller und billiger ist.
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

# Integration: Verbindet den API Gateway mit dem ALB
# Der Gateway leitet Anfragen direkt an den ALB weiter
resource "aws_apigatewayv2_integration" "main" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "http://${aws_lb.main.dns_name}" # Richtig
  integration_method = "ANY"
}

# Route: Leitet alle Anfragen (ANY /...) an die Integration weiter
resource "aws_apigatewayv2_route" "main" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# Stage: Stellt die API bereit (z.B. unter /dev oder /v1)
# $default stellt automatisch bereit
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}