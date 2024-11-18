resource "aws_ssm_parameter" "website_bucket_name" {
  name        = "/${var.project_name}/${var.environment}/s3-bucket-name"
  description = "S3 bucket name for website"
  type        = "String"
  value       = aws_s3_bucket.website.id
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  name        = "/${var.project_name}/${var.environment}/cloudfront-distribution-id"
  type        = "String"
  value       = aws_cloudfront_distribution.website.id
} 