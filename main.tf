# 全局数据源
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 基础设施模块
module "infrastructure" {
  source = "./infrastructure"

  aws_region = var.aws_region
  environment = var.environment
  project_name = var.project_name
  personal_website_s3_domain_name = var.domain_name
  domain_aliases = var.domain_aliases
  github_repo = var.github_repo
  alert_email = var.alert_email
  
  providers = {
    aws = aws
    aws.us-east-1 = aws.us_east_1
    aws.backup_region = aws.backup_region
  }
}

# 输出重要信息
output "website_url" {
  value = "https://${var.domain_name}"
}
