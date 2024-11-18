resource "aws_lambda_function" "website" {
  filename         = "website_handler.zip"  # 需要创建Lambda处理函数
  function_name    = "${var.project_name}-handler"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"

  # 增加内存和超时设置
  memory_size     = 256
  timeout         = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.website.id
      REGION      = var.aws_region
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

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

# 添加基础Lambda执行权限
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 添加S3访问权限
resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project_name}-lambda-s3-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.website.arn}/*"
        ]
      }
    ]
  })
} 