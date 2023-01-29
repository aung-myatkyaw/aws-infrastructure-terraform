variable "server_tag_value" {
  description = "Tag Value for server"
  default     = "vpn-server"
}

variable "configs_bucket_name" {
  description = "Storage Bucket for Config files"
  default     = "config-files-amk-152"
}

variable "ec2_instance_types" {
  description = "Instance Types"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "vpn_ec2_key_name" {
  description = "Server EC2 Key Name"
  default     = "vpn-server"
}

variable "vpc_name_tag" {
  description = "Tag to search VPC id"
  default     = "singapore-vpc"
}
