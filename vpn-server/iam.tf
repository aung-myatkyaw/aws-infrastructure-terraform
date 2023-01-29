# Role for Maintenance Window Task
data "aws_iam_role" "maintenance_window_run_command" {
  name = "maintenance-window-run-command-role"
}

# Instance Profile for ECS Instance
data "aws_iam_instance_profile" "standard_ec2_instance_profile" {
  name = "Role-for-EC2-Instance"
}
