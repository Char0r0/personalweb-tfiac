# S3 bucket for backups (in another region)
resource "aws_s3_bucket" "backup" {
  provider = aws.backup_region
  bucket   = "${var.web_name}-${var.environment}-backup"

  tags = {
    Name        = "${var.web_name}-backup"
    Environment = var.environment
  }
}

# Bucket policy to allow cross-region access
resource "aws_s3_bucket_policy" "backup" {
  provider = aws.backup_region
  bucket   = aws_s3_bucket.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossRegionAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_backup_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backup.arn,
          "${aws_s3_bucket.backup.arn}/*"
        ]
      }
    ]
  })
}

# Lambda permission for S3 trigger
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.personal_website.arn
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.personal_website.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.backup.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Lambda code packaging
data "archive_file" "backup_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup/backup.py"
  output_path = "${path.module}/lambda/backup/backup.zip"
}

# Lambda function configuration
resource "aws_lambda_function" "backup" {
  filename         = data.archive_file.backup_lambda.output_path
  function_name    = "${var.project_name}-backup"
  role            = aws_iam_role.lambda_backup_role.arn
  handler         = "backup.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256
  source_code_hash = data.archive_file.backup_lambda.output_base64sha256

  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.personal_website.id
      BACKUP_BUCKET = aws_s3_bucket.backup.id
    }
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "backup_lambda_role" {
  name = "${var.project_name}-backup-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM role policy for Lambda
resource "aws_iam_role_policy" "backup_lambda_policy" {
  name = "${var.project_name}-backup-lambda-policy"
  role = aws_iam_role.lambda_backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.personal_website.arn,
          "${aws_s3_bucket.personal_website.arn}/*",
          aws_s3_bucket.backup.arn,
          "${aws_s3_bucket.backup.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}
  