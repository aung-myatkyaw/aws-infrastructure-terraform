// Store Terraform Backend State on S3 Bucket
terraform {
  backend "s3" {
    bucket         = "terraform-backend-state-amk-152"
    key            = "common/backend-state"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform_state_locks"
    encrypt        = true
    profile        = "yinko"
  }
}

// Define Provider and Region
provider "aws" {
  region  = "ap-south-1"
  profile = "yinko"
  alias   = "mumbai"
  default_tags {
    tags = {
      Region = "Mumbai"
    }
  }
}

// Define Provider and Region
provider "aws" {
  region  = "ap-southeast-1"
  profile = "yinko"
  default_tags {
    tags = {
      Region = "Singapore"
    }
  }
}
