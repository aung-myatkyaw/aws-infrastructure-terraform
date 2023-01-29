# Launch Template for Spot instance
resource "aws_launch_template" "vpn_server_template" {
  name = "VPN-Server-Launch-Template"

  iam_instance_profile {
    arn = data.aws_iam_instance_profile.standard_ec2_instance_profile.arn
  }

  key_name = aws_key_pair.ec2_key.key_name

  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      volume_size           = 8
      volume_type           = "gp3"
    }
  }

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  monitoring {
    enabled = false
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.vpn_server_sg.id
    ]
  }

  update_default_version = true
  image_id               = data.aws_ssm_parameter.ubuntu_image.value
  user_data              = filebase64("startup_script.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = var.server_tag_value
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = var.server_tag_value
    }
  }
}

resource "aws_key_pair" "ec2_key" {
  key_name   = var.vpn_ec2_key_name
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.rsa.private_key_pem
  file_permission = "0400"
  filename        = "${var.vpn_ec2_key_name}.pem"
}

resource "aws_s3_object" "vpn_server_staging_ssh_private_key" {
  key                    = "ec2-ssh/${var.vpn_ec2_key_name}.pem"
  content                = tls_private_key.rsa.private_key_pem
  bucket                 = data.aws_s3_bucket.config_bucket.id
  server_side_encryption = "AES256"
}

resource "aws_instance" "vpn_server" {
  # disable_api_termination = true

  launch_template {
    id      = aws_launch_template.vpn_server_template.id
    version = "$Default"
  }
  instance_type = var.ec2_instance_types[0]
  subnet_id     = random_shuffle.subnet_for_vpn.result[0]
  tags = {
    "Name" = var.server_tag_value
  }
  lifecycle {
    ignore_changes = [ami, user_data, launch_template]
  }
}

# Elastic IP
resource "aws_eip" "vpn_server_ip" {
  instance = aws_instance.vpn_server.id
  tags = {
    "Name" = var.server_tag_value
  }
  vpc = true
}

# Security Group
resource "aws_security_group" "vpn_server_sg" {
  name   = var.server_tag_value
  vpc_id = data.aws_vpc.singapore_vpc.id
  tags = {
    "Name" = var.server_tag_value
  }
  description = "SG for VPN Server"

  # Custom Ports
  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 11979
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    to_port          = 11979
  }

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 26542
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    to_port          = 26542
  }

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 26542
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "udp"
    to_port          = 26542
  }

  # End of Custom ports

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 443
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    to_port          = 443
  }
  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 80
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    to_port          = 80
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_ssm_association" "vpn_server_cloud_watch_update" {
  association_name            = "Cloud_Watch_Agent_For_VPN_server"
  apply_only_at_cron_interval = true
  name                        = "AWS-ConfigureAWSPackage"
  parameters = {
    "action"           = "Install"
    "installationType" = "Uninstall and reinstall"
    "name"             = "AmazonCloudWatchAgent"
  }
  schedule_expression = "cron(0 23 ? * SUN *)"

  targets {
    key = "tag:Name"
    values = [
      var.server_tag_value
    ]
  }
}

resource "aws_ssm_maintenance_window" "vpn_server_maintenace_window" {
  allow_unassociated_targets = false
  cutoff                     = 0
  description                = "Patching Windows for VPN Server"
  duration                   = 1
  enabled                    = true
  name                       = var.server_tag_value
  schedule                   = "cron(0 22 ? * SUN *)"
  schedule_timezone          = "Asia/Yangon"
}

resource "aws_ssm_maintenance_window_target" "vpn_server_target" {
  window_id     = aws_ssm_maintenance_window.vpn_server_maintenace_window.id
  description   = "Target for VPN Server EC2 Instance"
  name          = var.server_tag_value
  resource_type = "INSTANCE"

  # depends_on = [
  #   aws_spot_fleet_request.vpn_server_staging_fleet_request
  # ]

  targets {
    key = "tag:Name"
    values = [
      var.server_tag_value
    ]
  }
}

resource "aws_ssm_maintenance_window_task" "vpn_server_window_task" {
  cutoff_behavior  = "CANCEL_TASK"
  description      = "Patching Run Command for Ubuntu"
  max_concurrency  = "100%"
  max_errors       = "50%"
  name             = "VPN-Server-Ubuntu-Patching"
  priority         = 1
  service_role_arn = data.aws_iam_role.maintenance_window_run_command.arn
  task_arn         = "AWS-RunPatchBaseline"
  task_type        = "RUN_COMMAND"
  window_id        = aws_ssm_maintenance_window.vpn_server_maintenace_window.id

  targets {
    key = "WindowTargetIds"
    values = [
      aws_ssm_maintenance_window_target.vpn_server_target.id
    ]
  }

  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"
      timeout_seconds  = 600

      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.vpn_server_patching_task_log_group.name
        cloudwatch_output_enabled = true
      }

      parameter {
        name = "Operation"
        values = [
          "Install",
        ]
      }
      parameter {
        name = "RebootOption"
        values = [
          "RebootIfNeeded",
        ]
      }
    }
  }
}

// Cloud Watch Log Group
resource "aws_cloudwatch_log_group" "vpn_server_patching_task_log_group" {
  name              = "/aws/ssm/vpn-server-patching"
  retention_in_days = 30
}
