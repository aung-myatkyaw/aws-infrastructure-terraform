data "aws_ssm_parameter" "ubuntu_image" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/arm64/hvm/ebs-gp2/ami-id"
}

# Get the VPC ID
data "aws_vpc" "singapore_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name_tag]
  }
}

# Get the Subnets in Singapore Region
data "aws_subnets" "singapore_public_subnets_data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.singapore_vpc.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["Public"]
  }
}

resource "random_shuffle" "subnet_for_vpn" {
  input        = data.aws_subnets.singapore_public_subnets_data.ids
  result_count = 1
}

// Configurations Bucket for Singapore Region
data "aws_s3_bucket" "config_bucket" {
  bucket = var.configs_bucket_name
}
