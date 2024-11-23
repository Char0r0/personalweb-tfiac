data "aws_route53_zone" "personal_website_main" {
  name = var.personal_website_s3_domain_name
}

resource "aws_route53_record" "personal_website_a" {
  zone_id = data.aws_route53_zone.personal_website_main.zone_id
  name    = var.personal_website_s3_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.personal_website_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.personal_website_s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "personal_website_www" {
  zone_id = data.aws_route53_zone.personal_website_main.zone_id
  name    = "www.${var.personal_website_s3_domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.personal_website_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.personal_website_s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
