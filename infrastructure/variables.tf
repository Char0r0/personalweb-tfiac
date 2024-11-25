terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [ aws.us-east-1, aws.backup_region ]
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "web_name" {
  description = "Website name for resource identification"
  type        = string
  default     = "charles-zh-website"
}

variable "personal_website_s3_domain_name" {
  description = "Primary domain name for the website"
  type        = string
  default     = "charles-zh.com"
}

variable "domain_aliases" {
  description = "List of subdomains (e.g., www, api)"
  type        = list(string)
  default     = ["www", "api"]
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "personal-website"
}

variable "github_repo" {
  description = "GitHub repository name (format: username/repo)"
  type        = string
  default     = "your-github-username/your-repo-name"
}

variable "website_repo" {
  description = "Website repository name (format: username/repo)"
  type        = string
  default     = "your-github-username/your-website-repo"
}

variable "backup_region" {
  description = "AWS region for backup resources"
  type        = string
  default     = "us-west-1"
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 0 * * ? *)"  # Runs daily at midnight
}

variable "backup_bucket_size_threshold" {
  description = "Threshold for backup bucket size alarm (bytes)"
  type        = number
  default     = 5368709120  # 5GB in bytes
}

variable "alert_email" {
  description = "Email address for backup alerts"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {
    Environment = "prod"
    Project     = "personal-website"
    ManagedBy  = "terraform"
  }
}

variable "enable_alerts" {
  description = "Whether to enable CloudWatch alerts"
  type        = bool
  default     = false  # Alerts disabled by default
}