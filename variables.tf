variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "env name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "project name"
  type        = string
  default     = "personal-website"
}

variable "domain_name" {
  description = "domain name"
  type        = string
  default     = "charles-zh.com"
}

variable "domain_aliases" {
  description = "domain aliases"
  type        = list(string)
  default     = ["www", "blog", "api"]
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

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "personalweb"
  }
}

variable "alert_email" {
  description = "Email address for alerts and notifications"
  type        = string
}