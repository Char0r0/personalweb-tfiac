output "website_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "website_domain" {
  description = "website domain name"
  value       = var.domain_name
}

output "certificate_arn" {
  description = "SSL certificate arn"
  value       = aws_acm_certificate.cert.arn
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_api.website.api_endpoint
}

output "deployer_access_key_id" {
  description = "website deployer access key id"
  value       = aws_iam_access_key.website_deployer.id
  sensitive   = true
}

output "deployer_secret_access_key" {
  description = "website deployer secret access key"
  value       = aws_iam_access_key.website_deployer.secret
  sensitive   = true
} 