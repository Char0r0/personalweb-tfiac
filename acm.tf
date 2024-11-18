resource "aws_acm_certificate" "cert" {
  provider                  = aws.us-east-1  # CloudFront要求证书必须在us-east-1区域
  domain_name              = var.domain_name
  subject_alternative_names = var.domain_aliases
  validation_method        = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
