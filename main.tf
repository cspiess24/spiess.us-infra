data "aws_cloudfront_cache_policy" "web_hosting" {
  name = "Managed-CachingOptimized"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.environment != "Prod" ? "${var.environment}.spiess.us" : "spiess.us"
  validation_method = "DNS"

  tags = {
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "web_hosting" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
      type  = dvo.resource_record_type
    }
  }
  zone_id = var.cloudflare_zone_id
#   type    = "CNAME"
  ttl     = 1
}

resource "aws_acm_certificate_validation" "web_hosting" {
  certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
  validation_record_fqdns = [for record in cloudflare_record.web_hosting : record.hostname]
}

resource "aws_s3_bucket" "web_hosting" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "web_hosting" {
  bucket = aws_s3_bucket.web_hosting.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "web_hosting" {}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.web_hosting.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_hosting.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["${var.environment}.spiess.us"]

  default_cache_behavior {
    cache_policy_id = data.aws_cloudfront_cache_policy.web_hosting.id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    acm_certificate_arn = data.some_certificate_id
    minimum_protocol_version = var.minimum_protocol_version
    ssl_support_method = "sni_only"
  }
}
