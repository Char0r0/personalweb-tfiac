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
  pw_acm_certificate_arn = aws_acm_certificate.personal_website_cert.arn
  alert_email = var.alert_email
  
  providers = {
    aws = aws
    aws.us-east-1 = aws.us_east_1
    aws.backup_region = aws.backup_region
  }
}

module "iam" {
  source = "./iam"
  
  project_name = var.project_name
  website_bucket_arn = module.infrastructure.website_bucket_arn
  website_bucket_name_parameter_arn = module.infrastructure.website_bucket_name_parameter_arn
  aws_region = var.aws_region
  environment = var.environment
  
  depends_on = [module.infrastructure]
}

# 输出重要信息
output "website_url" {
  value = "https://${var.domain_name}"
}

output "cloudfront_distribution_id" {
  value = module.infrastructure.cloudfront_distribution_id
}

output "website_bucket_name" {
  value = module.infrastructure.website_bucket_name
}

output "backup_bucket_name" {
  value = module.infrastructure.backup_bucket_name
} 