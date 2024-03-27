// Store Terraform Backend State on S3 Bucket
terraform {
  backend "s3" {
    bucket         = "terraform-backend-state-amk-152"
    key            = "vpn-server/backend-state"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform_state_locks"
    encrypt        = true
    profile        = "amk"
  }
}

// Define Provider and Region
provider "aws" {
  region  = "ap-southeast-1"
  profile = "amk"
  default_tags {
    tags = {
      Region = "Singapore"
    }
  }
}
