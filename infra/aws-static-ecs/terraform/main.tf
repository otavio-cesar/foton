locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "static-ecs"
  }

  root_domain = var.custom_domain_names[0]

  active_frontend_origin_id = var.active_runtime_region == "us-east-1" ? "frontend-s3-us" : "frontend-s3"
  active_api_origin_id      = var.active_runtime_region == "us-east-1" ? "api-alb-us" : "api-alb"
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${local.name}-frontend"
  description                       = "CloudFront access to private frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_acm_certificate" "frontend" {
  provider = aws.us_east_1
  count    = length(var.custom_domain_names) > 0 ? 1 : 0

  domain_name               = var.custom_domain_names[0]
  subject_alternative_names = slice(var.custom_domain_names, 1, length(var.custom_domain_names))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "frontend" {
  count = var.manage_route53_zone ? 1 : 0

  name = local.root_domain

  tags = {
    Name = local.root_domain
  }
}

resource "aws_route53_record" "frontend_certificate_validation" {
  for_each = var.manage_route53_zone && length(aws_acm_certificate.frontend) > 0 ? {
    for option in aws_acm_certificate.frontend[0].domain_validation_options : option.domain_name => {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  ttl             = 300
  type            = each.value.type
  zone_id         = aws_route53_zone.frontend[0].zone_id
}

resource "aws_acm_certificate_validation" "frontend" {
  provider = aws.us_east_1
  count    = var.enable_custom_domain ? 1 : 0

  certificate_arn         = aws_acm_certificate.frontend[0].arn
  validation_record_fqdns = [for record in aws_route53_record.frontend_certificate_validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = var.enable_custom_domain ? var.custom_domain_names : []

  dynamic "origin" {
    for_each = var.us_frontend_origin_domain_name != "" ? [1] : []

    content {
      domain_name              = var.us_frontend_origin_domain_name
      origin_id                = "frontend-s3-us"
      origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
    }
  }

  dynamic "origin" {
    for_each = var.us_api_origin_domain_name != "" ? [1] : []

    content {
      domain_name = var.us_api_origin_domain_name
      origin_id   = "api-alb-us"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = local.active_frontend_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = local.active_api_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "CloudFront-Forwarded-Proto", "Content-Type", "Origin"]

      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/health"
    target_origin_id       = local.active_api_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.enable_custom_domain ? aws_acm_certificate_validation.frontend[0].certificate_arn : null
    cloudfront_default_certificate = var.enable_custom_domain ? false : true
    minimum_protocol_version       = var.enable_custom_domain ? "TLSv1.2_2021" : null
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
  }

  lifecycle {
    precondition {
      condition = (
        var.active_runtime_region == "us-east-1" &&
        var.us_frontend_origin_domain_name != "" &&
        var.us_api_origin_domain_name != ""
      )
      error_message = "The global edge stack requires both us-east-1 origin domains."
    }
  }
}

resource "aws_route53_record" "frontend_alias_a" {
  for_each = var.manage_route53_zone && var.enable_custom_domain ? toset(var.custom_domain_names) : toset([])

  name    = each.value
  type    = "A"
  zone_id = aws_route53_zone.frontend[0].zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
  }
}

resource "aws_route53_record" "frontend_alias_aaaa" {
  for_each = var.manage_route53_zone && var.enable_custom_domain ? toset(var.custom_domain_names) : toset([])

  name    = each.value
  type    = "AAAA"
  zone_id = aws_route53_zone.frontend[0].zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
  }
}
