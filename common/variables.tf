variable "main_cidr_block" {
  description = "Main CIDR Block for All Regions"
  default     = "10.0.0.0/8"
}

variable "aws_region_list_for_cidr" {
  description = "AWS Region List for creating CIDR Blocks"
  default = {
    "ap-southeast-1" = 0
    "ap-south-1"     = 1
    "us-west-2"      = 2
  }
}

variable "configs_bucket_name" {
  description = "Storage Bucket for Config files"
  default     = "config-files-amk-152"
}

variable "codedeploy_bucket_name" {
  description = "Bucket for CodeDeploy"
  default     = "codedeploy-artifacts-storage-amk-{{REGION_NAME}}"
}

variable "subscription_emails" {
  description = "Create Topic Subscriptions with these emails"
  type        = list(string)
  default     = ["aungmyatkyaw.kk@gmail.com"]
}

