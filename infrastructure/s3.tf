# s3-main.terraform

# S3 Bucket for static website
resource "aws_s3_bucket" "personal_website" {
  bucket = "${var.web_name}-${var.environment}"

  tags = {
    Name = var.web_name
    Environment = var.environment
  }
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "personal_website" {
  bucket = aws_s3_bucket.personal_website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.personal_website_s3_domain_name}"]
    max_age_seconds = 3000
  }
}

# Lifecycle rule configuration
resource "aws_s3_bucket_lifecycle_configuration" "personal_website" {
  bucket = aws_s3_bucket.personal_website.id

  rule {
    id      = "cleanup_old_versions"
    status  = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Unblock public access to the bucket (AWS requirements)
resource "aws_s3_bucket_public_access_block" "personal_website" {
  bucket = aws_s3_bucket.personal_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Versioning configuration for the bucket
resource "aws_s3_bucket_versioning" "personal_website" {
  bucket = aws_s3_bucket.personal_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "personal_website" {
  bucket = aws_s3_bucket.personal_website.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Server-side encryption configuration for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "personal_website_encryption" {
  bucket = aws_s3_bucket.personal_website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "personal_website_policy" {
  depends_on = [ aws_s3_bucket_public_access_block.personal_website, aws_cloudfront_origin_access_identity.personal_website_s3_distribution ]
  bucket = aws_s3_bucket.personal_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = {
          "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.personal_website_s3_distribution.id}"
        },
        "Action" = [ "s3:GetObject" ],
        "Resource" = "arn:aws:s3:::${var.web_name}-${var.environment}/*"
      }
    ]
  })
}

# S3 bucket logging
resource "aws_s3_bucket" "pw_log_bucket" {
  bucket = "${var.web_name}-${var.environment}-logs"

  tags = {
    Name = "${var.web_name}-${var.environment}-logs"
    Environment = var.environment
  }
}

# Enable S3 bucket logging
resource "aws_s3_bucket_logging" "personal_website_logging" {
  bucket = aws_s3_bucket.personal_website.id
  
  target_bucket = aws_s3_bucket.pw_log_bucket.id
  target_prefix = "s3-access-logs/"
}