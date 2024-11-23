resource "aws_acm_certificate" "personal_website_cert" {
  provider                  = aws.us-east-1
  domain_name              = var.personal_website_s3_domain_name
  subject_alternative_names = var.domain_aliases
  validation_method        = "DNS"

  tags = {
    Name = "personal-website-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "personal_website_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.personal_website_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.personal_website_main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "personal_website_cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.personal_website_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.personal_website_cert_validation : record.fqdn]
}
