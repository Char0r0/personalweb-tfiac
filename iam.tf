# 创建IAM用户
resource "aws_iam_user" "website_deployer" {
  name = "${var.project_name}-deployer"
}

# 创建访问密钥
resource "aws_iam_access_key" "website_deployer" {
  user = aws_iam_user.website_deployer.name
}

# 创建IAM策略
resource "aws_iam_policy" "website_deployment" {
  name        = "${var.project_name}-deployment-policy"
  description = "allow deploy website to s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.website_bucket_name.arn
        ]
      }
    ]
  })
}

# 将策略附加到用户
resource "aws_iam_user_policy_attachment" "website_deployment" {
  user       = aws_iam_user.website_deployer.name
  policy_arn = aws_iam_policy.website_deployment.arn
} 