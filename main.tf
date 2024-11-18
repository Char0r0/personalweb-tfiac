# 本地变量
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    ManagedBy  = "terraform"
  }

  domain_aliases = [for alias in var.domain_aliases : "${alias}.${var.domain_name}"]
}
