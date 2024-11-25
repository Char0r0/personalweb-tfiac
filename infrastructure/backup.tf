# 备份用的 S3 存储桶（在另一个区域）
resource "aws_s3_bucket" "backup" {
  provider = aws.backup_region
  bucket   = "${var.web_name}-${var.environment}-backup"

  tags = {
    Name        = "${var.web_name}-backup"
    Environment = var.environment
  }
}

# 允许跨区域访问的桶策略
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

# 备份生命周期规则
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  provider = aws.backup_region
  bucket   = aws_s3_bucket.backup.id

  rule {
    id     = "delete_old_backups"
    status = "Enabled"

    expiration {
      days = 90  # 90天后自动删除备份
    }
  }
}

# 添加 S3 触发 Lambda 的配置
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.personal_website.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.backup.arn
    events = [
      "s3:ObjectCreated:*",  # 创建或更新文件时触发
      "s3:ObjectRemoved:*"   # 删除文件时触发
    ]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# 添加允许 S3 触发 Lambda 的权限
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.personal_website.arn
}

# EventBridge 规则触发 Lambda
resource "aws_cloudwatch_event_rule" "backup_trigger" {
  name                = "${var.project_name}-backup-trigger"
  description         = "每天触发备份"
  schedule_expression = "cron(0 0 * * ? *)"  # 每天午夜触发
}

resource "aws_cloudwatch_event_target" "backup_lambda" {
  rule      = aws_cloudwatch_event_rule.backup_trigger.name
  target_id = "BackupLambda"
  arn       = aws_lambda_function.backup.arn
}

# Lambda 权限
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_trigger.arn
}


# Lambda 代码打包
data "archive_file" "backup_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup/backup.py"
  output_path = "${path.module}/lambda/backup/backup.zip"
}

# Lambda 函数
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

# 添加 Lambda 的 IAM 角色
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

# 修改 Lambda 的 IAM 角色策略
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
  