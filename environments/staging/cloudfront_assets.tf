# 1. Erstellt die sichere Verbindung
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "asset-oac-${var.project_name}"
  description                       = "OAC for S3 Asset Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}


# 2. Die CloudFront Distribution (CDN)
resource "aws_cloudfront_distribution" "assets_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html" # Nicht direkt relevant für Bilder, aber gute Praxis

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "S3-Assets-Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Assets-Origin"
    viewer_protocol_policy = "redirect-to-https"
    
    # Empfohlen: Caching optimieren für statische Dateien
    # Nutzt Standard-Richtlinien für maximale Performance
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    
    compress               = true
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 3. S3 Bucket Policy (Nur CloudFront erlauben)
resource "aws_s3_bucket_policy" "assets_policy" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets_oac_read.json
}

# 4. Data Source für die Policy
data "aws_iam_policy_document" "assets_oac_read" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.assets.arn}/*",
    ]
    
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      # Dies schränkt den Zugriff auf Ihre spezifische CDN-Distribution ein
      values   = [aws_cloudfront_distribution.assets_cdn.arn]
    }
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "car-configurator-staging-assets" 
  tags = {
    Name = "Car Configurator Assets"
  }
}