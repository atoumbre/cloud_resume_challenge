terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# 1. Create DNS CNAME records in Cloudflare for Validation
resource "cloudflare_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.resource_record_name
  content = each.value.resource_record_value
  type    = each.value.resource_record_type
  proxied = false # Must be grey cloud for validation
}

# 2. Wait for Certificate to be fully Issued (Important trigger!)
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in cloudflare_record.validation : r.hostname]
}

# 3. Create actual Domain Pointers in Cloudflare (Targeting CloudFront)
resource "cloudflare_record" "apex" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = aws_cloudfront_distribution.cdn.domain_name
  type    = "CNAME"
  proxied = false # Grey cloud as best practice for static cdns
}

resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content = aws_cloudfront_distribution.cdn.domain_name
  type    = "CNAME"
  proxied = false
}

# Keep Output for manual verification fallback if needed
output "acm_validation_records" {
  description = "CNAME records created in Cloudflare for SSL certificate validation"
  value = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}
