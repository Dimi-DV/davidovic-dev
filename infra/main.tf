# davidovic.dev — public portfolio infra.
#
#   S3 (sealed, OAC-only) ← CloudFront (public, HTTPS) ← Route 53 apex + www
#   Zone is OWNED by ~/serb-ops/infra — looked up by name here, never modified.
#
#   terraform init && terraform apply              # builds everything, NO apex DNS yet
#   ... review the site at output cloudfront_url ...
#   terraform apply -var enable_apex_dns=true      # go live

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1" # CloudFront certs must live here
}

variable "region" {
  type    = string
  default = "eu-central-1"
}
variable "zone_name" {
  type    = string
  default = "davidovic.dev"
}
variable "github_repo" {
  type    = string
  default = "Dimi-DV/davidovic-dev"
}
variable "enable_apex_dns" {
  type    = bool
  default = false # flip to true ONLY after Dimi approves the content (CLAUDE.md rule 3)
}

data "aws_route53_zone" "main" {
  name = var.zone_name
}

data "aws_caller_identity" "current" {}

# ---- S3 ---------------------------------------------------------------------------
resource "aws_s3_bucket" "site" {
  bucket = "davidovic-dev-portfolio-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cf_only" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "CloudFrontOACRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site.arn } }
    }]
  })
}

# ---- TLS (apex + www) ----------------------------------------------------------------
resource "aws_acm_certificate" "site" {
  provider                  = aws.use1
  domain_name               = var.zone_name
  subject_alternative_names = ["www.${var.zone_name}"]
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "site" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ---- CloudFront (public — no auth function) -------------------------------------------
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "davidovic-dev-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.zone_name, "www.${var.zone_name}"]
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS managed CachingOptimized
  }

  custom_error_response {
    error_code         = 403 # S3+OAC returns 403 for missing keys
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ---- DNS (gated until content approval) -------------------------------------------------
locals {
  apex_names = var.enable_apex_dns ? [var.zone_name, "www.${var.zone_name}"] : []
}

resource "aws_route53_record" "site_a" {
  for_each = toset(local.apex_names)
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = each.value
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_aaaa" {
  for_each = toset(local.apex_names)
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = each.value
  type     = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# ---- GitHub Actions OIDC deploy role (provider already exists in the account) -------------
resource "aws_iam_role" "deploy" {
  name = "davidovic-dev-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "davidovic-dev-deploy"
  role = aws_iam_role.deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = aws_s3_bucket.site.arn },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = "${aws_s3_bucket.site.arn}/*" },
      { Effect = "Allow", Action = ["cloudfront:CreateInvalidation"], Resource = aws_cloudfront_distribution.site.arn }
    ]
  })
}

# ---- Outputs --------------------------------------------------------------------------------
output "cloudfront_url" { value = "https://${aws_cloudfront_distribution.site.domain_name}" }
output "site_url" { value = "https://${var.zone_name} (live only once enable_apex_dns=true)" }
output "SITE_BUCKET" { value = aws_s3_bucket.site.id }
output "CF_DIST_ID" { value = aws_cloudfront_distribution.site.id }
output "AWS_DEPLOY_ROLE_ARN" { value = aws_iam_role.deploy.arn }
output "AWS_REGION" { value = var.region }
