# Instance Profile
resource "aws_iam_instance_profile" "standard_ec2_instance_profile" {
  name = "Role-for-EC2-Instance"
  role = aws_iam_role.standard_ec2_instance_role.name
}

// Instance Role for Standard EC2 instances
resource "aws_iam_role" "standard_ec2_instance_role" {
  name = "Role-for-EC2-Instance"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description = "Allows Staging EC2 instances to call AWS services on your behalf."
  managed_policy_arns = [
    aws_iam_policy.codedeploy_s3_policy.arn,
    aws_iam_policy.ecr_pull_policy.arn,
    aws_iam_policy.ecr_push_policy.arn,
    aws_iam_policy.ip_assign_policy.arn,
    data.aws_iam_policy.cloudwatch_server_policy.arn,
    data.aws_iam_policy.ssm_instance_policy.arn
  ]

  inline_policy {
    name = "CloudWatchAgentPutLogsRetention"
    policy = jsonencode(
      {
        Statement = [
          {
            Action   = "logs:PutRetentionPolicy"
            Effect   = "Allow"
            Resource = "*"
          },
        ]
        Version = "2012-10-17"
      }
    )
  }
}

// Policy for Codedeploy S3 Access
resource "aws_iam_policy" "codedeploy_s3_policy" {
  name = "CodeDeployProfileS3AccessPolicy"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "s3:Get*",
            "s3:List*",
          ]
          Effect = "Allow"
          Resource = [
            data.aws_s3_bucket.config_bucket.arn,
            format("%s%s", data.aws_s3_bucket.config_bucket.arn, "/*"),
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

// Policy for ECR image pull
resource "aws_iam_policy" "ecr_pull_policy" {
  description = "Pull Images From ECR"
  name        = "ECR-pull-policy"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:GetAuthorizationToken"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

// Policy for ECR image push
resource "aws_iam_policy" "ecr_push_policy" {
  description = "Push Images To ECR"
  name        = "ECR-push-policy"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

// Policy for EIP modification
resource "aws_iam_policy" "ip_assign_policy" {
  name        = "ec2-ip-assign-and-pipeline-start-policy"
  description = "Policy for IP modification of EC2"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ec2:DisassociateAddress",
            "ec2:AssociateAddress",
            "ec2:DescribeAddresses"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
      Version = "2012-10-17"
    }
  )
}

// Policy for SSM log group
resource "aws_iam_policy" "ssm_logs_policy" {
  name        = "ec2-ssm-put-logs-to-cloudwatch-policy"
  description = "Policy for putting logs for SSM operations on EC2"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:DescribeLogGroups"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ]
          Resource = "arn:aws:logs:*:*:log-group:/aws/ssm/*"
        }
      ]
      Version = "2012-10-17"
    }
  )
}

# Get the policy by name
data "aws_iam_policy" "ssm_instance_policy" {
  name = "AmazonSSMManagedInstanceCore"
}

# Get the policy by name
data "aws_iam_policy" "cloudwatch_server_policy" {
  name = "CloudWatchAgentServerPolicy"
}

# Role for EC2 Spot Instance Fleet Request
resource "aws_iam_role" "ec2_spot_fleet_tagging" {
  name = "aws-ec2-spot-fleet-tagging-role"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "spotfleet.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  managed_policy_arns = [
    data.aws_iam_policy.aws_spot_fleet_tagging.arn
  ]
}

# Get the policy by name
data "aws_iam_policy" "aws_spot_fleet_tagging" {
  name = "AmazonEC2SpotFleetTaggingRole"
}

# Role for Maintenance windows run command
resource "aws_iam_role" "maintenance_window_run_command" {
  name = "maintenance-window-run-command-role"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ssm.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description = "Performs maintenance window tasks on your behalf"
  managed_policy_arns = [
    aws_iam_policy.maintenance_window_run_command_policy.arn
  ]
}

# Policy for Maintenance windows run command
resource "aws_iam_policy" "maintenance_window_run_command_policy" {
  name = "maintenance-window-run-command-role-policy"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ssm:SendCommand",
            "ssm:CancelCommand",
            "ssm:ListCommands",
            "ssm:ListCommandInvocations",
            "ssm:GetCommandInvocation",
            "ssm:ListTagsForResource",
            "ssm:GetParameters",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "resource-groups:ListGroups",
            "resource-groups:ListGroupResources",
          ]
          Effect = "Allow"
          Resource = [
            "*",
          ]
        },
        {
          Action = [
            "tag:GetResources",
          ]
          Effect = "Allow"
          Resource = [
            "*",
          ]
        },
        {
          Action = "iam:PassRole"
          Condition = {
            StringEquals = {
              "iam:PassedToService" = [
                "ssm.amazonaws.com",
              ]
            }
          }
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

// Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "monitoring.rds.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  managed_policy_arns = [
    data.aws_iam_policy.rds_monitoring_policy.arn
  ]
}

# Get the policy by name
data "aws_iam_policy" "rds_monitoring_policy" {
  name = "AmazonRDSEnhancedMonitoringRole"
}

# Role for Lambda Function of processing SNS noti for spot instance changes
resource "aws_iam_role" "lambda_process_sns_role" {
  name = "SNS-Publish-For-Lambda"
  path = "/service-role/"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  managed_policy_arns = [
    aws_iam_policy.lambda_sns_process_policy.arn,
    aws_iam_policy.lambda_logs_policy.arn,
    aws_iam_policy.lambda_sns_publish_policy.arn
  ]
}

resource "aws_iam_policy" "lambda_sns_process_policy" {
  name = "Lambda-SNS-Process-Policy"
  policy = jsonencode(
    {
      Statement = [
        {
          Action   = "ec2:DescribeTags"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "ssm:GetParameter"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
      Version = "2012-10-17"
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "lambda_logs_policy" {
  name = "Lambda-Logging-Policy"
  path = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            "*",
          ]
        }
      ]
      Version = "2012-10-17"
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "lambda_sns_publish_policy" {
  name = "Lambda-SNS-Publish-Policy"
  path = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "sns:Publish",
          ]
          Effect   = "Allow"
          Resource = "arn:aws:sns:*:*:*"
        },
      ]
      Version = "2012-10-17"
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}
