resource "aws_cloudfront_origin_access_identity" "personal_website_s3_distribution" {
    comment = "Access to personal website S3 bucket"
}

resource "aws_cloudfront_distribution" "personal_website_api_distribution" {
    depends_on = [ aws_cloudfront_origin_access_identity.personal_website_s3_distribution ]

    origin {
      domain_name = aws_s3_bucket.personal_website.bucket_regional_domain_name
      origin_id = aws_s3_bucket.personal_website.id

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.personal_website_s3_distribution.cloudfront_access_identity_path
      }
    }

    enabled = true
    is_ipv6_enabled = true
    default_root_object = "index.html"

    aliases = concat([var.personal_website_s3_domain_name], [for subdomain in var.domain_aliases : "${subdomain}.${var.personal_website_s3_domain_name}"])

    default_cache_behavior {
        allowed_methods = ["GET", "HEAD"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = aws_s3_bucket.personal_website.id
        viewer_protocol_policy = "redirect-to-https"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
    }

    price_class = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    custom_error_response {
        error_caching_min_ttl = 0
        error_code = 403
        response_code = 200
        response_page_path = "/index.html"
    }

    custom_error_response {
        error_caching_min_ttl = 0
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
    }

    tags = {
      Name = "personal-website-CloudFront-distribution"
    }

    viewer_certificate {
        acm_certificate_arn = var.pw_acm_certificate_arn
        minimum_protocol_version = "TLSv1.2_2021"
        ssl_support_method = "sni-only"
    }
} 