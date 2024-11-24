terraform {
  backend "s3" {
    bucket         = "personal-website-tf-statefiles"
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
} 