terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.59.0"
    }
  }
}
provider "aws" {
  region = "ap-southeast-2" # Choose the region you want
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "backup_region"
  region = "us-west-1"
}
