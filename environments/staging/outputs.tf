output "frontend_url" {
  description = "The URL for the Angular frontend (CloudFront)"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "api_backend_url" {
  description = "The URL for the backend API (API Gateway)"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = aws_db_instance.orders.endpoint
  sensitive   = true
}


output "cdn_assets__domain_name" {
  value = aws_cloudfront_distribution.assets_cdn.domain_name
}