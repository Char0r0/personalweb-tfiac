terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "personal-website/terraform.tfstate"
    region = "ap-southeast-2"
    
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
} 