# Add data source
data "aws_caller_identity" "current" {}

# Create IAM user
resource "aws_iam_user" "website_deployer" {
  name = "${var.project_name}-deployer"
}

# Create access key
resource "aws_iam_access_key" "website_deployer" {
  user = aws_iam_user.website_deployer.name
}

# Create IAM policy
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
          aws_s3_bucket.personal_website.arn,
          "${aws_s3_bucket.personal_website.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = var.environment
            "aws:ResourceTag/Project" = var.project_name
          }
        }
      }
    ]
  })
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "website_deployment" {
  user       = aws_iam_user.website_deployer.name
  policy_arn = aws_iam_policy.website_deployment.arn
}

# Website deployment role
resource "aws_iam_role" "website_deployment_role" {
  name = "${var.project_name}-deployment-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-deployment-role"
    Environment = var.environment
    Project = var.project_name
  }
}

# Create role policy for website deployment
resource "aws_iam_role_policy" "website_deployment_policy" {
  name = "${var.project_name}-role-policy"
  role = aws_iam_role.website_deployment_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.personal_website.arn,
          "${aws_s3_bucket.personal_website.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment": var.environment
          }
        }
      }
    ]
  })
}

# Lambda backup role
resource "aws_iam_role" "lambda_backup_role" {
  name = "${var.project_name}-lambda-backup-role"

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

# Lambda backup policy
resource "aws_iam_role_policy" "lambda_backup_policy" {
  name = "${var.project_name}-lambda-backup-policy"
  role = aws_iam_role.lambda_backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
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
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
} 