variable "aws_region" {
  description = "AWS region"
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