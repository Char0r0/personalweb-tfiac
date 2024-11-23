# 备份用的 S3 存储桶（在另一个区域）
resource "aws_s3_bucket" "personal_website_backup" {
  provider = aws.backup_region
  bucket   = "${var.web_name}-${var.environment}-backup"

  tags = {
    Name        = "${var.web_name}-backup"
    Environment = var.environment
  }
}

# 备份存储桶的加密配置
resource "aws_s3_bucket_server_side_encryption_configuration" "backup_encryption" {
  provider = aws.backup_region
  bucket   = aws_s3_bucket.personal_website_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 备份存储桶的版本控制
resource "aws_s3_bucket_versioning" "backup" {
  provider = aws.backup_region
  bucket   = aws_s3_bucket.personal_website_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lambda 函数的 IAM 角色
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

# Lambda 函数的 IAM 策略
resource "aws_iam_role_policy" "backup_lambda_policy" {
  name = "${var.project_name}-backup-lambda-policy"
  role = aws_iam_role.backup_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.personal_website.arn,
          "${aws_s3_bucket.personal_website.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
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

# Lambda 函数
resource "aws_lambda_function" "personal_website_backup" {
  filename         = data.archive_file.backup_lambda.output_path
  function_name    = "${var.project_name}-backup"
  role            = aws_iam_role.backup_lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 300

  environment {
    variables = {
      SOURCE_REGION = var.aws_region
      SOURCE_BUCKET = aws_s3_bucket.personal_website.id
      BACKUP_BUCKET = aws_s3_bucket.backup.id
    }
  }

  depends_on = [
    aws_iam_role_policy.backup_lambda_policy
  ]
}

# 打包 Lambda 函数代码
data "archive_file" "backup_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/backup"
  output_path = "${path.module}/lambda/backup.zip"
}

# EventBridge 规则（每天执行一次备份）
resource "aws_cloudwatch_event_rule" "personal_website_backup" {
  name                = "${var.project_name}-backup-schedule"
  description         = "Schedule for website backup"
  schedule_expression = "cron(0 0 * * ? *)"  # 每天午夜执行
}

resource "aws_cloudwatch_event_target" "personal_website_backup" {
  rule      = aws_cloudwatch_event_rule.personal_website_backup.name
  target_id = "BackupWebsite"
  arn       = aws_lambda_function.personal_website_backup.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.personal_website_backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup.arn
} 