# --- 1. S3 Bucket (Privat) ---
# Der Bucket ist privat. Nur CloudFront kann darauf zugreifen.
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-bucket" # S3-Namen müssen global eindeutig sein
}

# --- 2. CloudFront Origin Access Control (OAC) ---
# Der moderne Weg, um CloudFront Zugriff auf S3 zu geben
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- 3. CloudFront (CDN) Distribution ---
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-${var.project_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Standard-Cache-Verhalten
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${var.project_name}"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Forward all headers, cookies, query strings (kann Caching reduzieren, aber sicher)
    # Besser: explizite Whitelists
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # WICHTIG für Angular (Single Page Application - SPA)
  # Leitet 403/404-Fehler auf index.html um, damit der Angular-Router übernimmt
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # Standard-CloudFront-Zertifikat
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # Weltweit verfügbar
    }
  }
}

# --- 4. S3 Bucket Policy ---
# Erlaubt CloudFront OAC das Lesen aus dem Bucket
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            # Stellt sicher, dass NUR diese spezifische CloudFront-Distribution Zugriff hat
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}