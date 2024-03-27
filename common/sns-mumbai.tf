// Notification Topic
resource "aws_sns_topic" "notification_topic" {
  provider = aws.mumbai
  name     = "dexon-sns-topic-${data.aws_region.mumbai.name}"
}

// Notification Subscriptions
resource "aws_sns_topic_subscription" "notification_topic_subscriptions" {
  provider  = aws.mumbai
  count     = length(var.subscription_emails)
  topic_arn = aws_sns_topic.notification_topic.arn
  protocol  = "email"
  endpoint  = var.subscription_emails[count.index]
}

// Topic Policy for Staging
resource "aws_sns_topic_policy" "notification_topic_policy" {
  provider = aws.mumbai
  arn      = aws_sns_topic.notification_topic.arn
  policy   = data.aws_iam_policy_document.sns_topic_policy.json
}

// policy document
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = ["SNS:Publish"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com", "events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.notification_topic.arn,
    ]
  }
  version = "2008-10-17"
}

// EventBridge Rule for spot fleet change in Current Region
resource "aws_cloudwatch_event_rule" "spot_fleet_change_event_notification_rule" {
  provider = aws.mumbai
  name     = "ec2-spot-fleet-change-${data.aws_region.mumbai.name}"
  event_pattern = jsonencode(
    {
      detail-type = [
        "EC2 Spot Fleet Instance Change",
        "EC2 Spot Fleet Information",
        "EC2 Spot Fleet Error",
        "EC2 Spot Instance Interruption Warning",
        "EC2 Instance Rebalance Recommendation"
      ]
      source = [
        "aws.ec2spotfleet",
        "aws.ec2"
      ]
    }
  )
}

// EventBridge Spot Change Noti Target in Current Region
resource "aws_cloudwatch_event_target" "spot_fleet_change_event_noti_target" {
  provider  = aws.mumbai
  target_id = "spot-change-trigger-lambda-function-to-process-sns-${data.aws_region.mumbai.name}"
  rule      = aws_cloudwatch_event_rule.spot_fleet_change_event_notification_rule.name
  arn       = aws_lambda_function.sns_email_process.arn
}

// EventBridge Rule for Pipeline State Change in Current Region
resource "aws_cloudwatch_event_rule" "codepipeline_event_notification_rule" {
  provider = aws.mumbai
  name     = "codepipeline-noti-${data.aws_region.mumbai.name}"
  event_pattern = jsonencode(
    {
      detail = {
        state = [
          "CANCELED",
          "SUPERSEDED",
          "FAILED",
          "SUCCEEDED",
          "RESUMED",
          "STARTED"
        ]
      }
      detail-type = [
        "CodePipeline Pipeline Execution State Change"
      ]
      source = [
        "aws.codepipeline"
      ]
    }
  )
}

// Archive Code For Lambda Function
data "archive_file" "sns_email_process_lambda_code" {
  type                    = "zip"
  source_content          = replace(file("./lambda/sns-email-process/main.py"), "{{TOPIC_ARN}}", aws_sns_topic.notification_topic.arn)
  source_content_filename = "main.py"
  output_path             = "./lambda/sns-email-process-${data.aws_region.mumbai.name}.zip"
}

// Lambda Function for Processing SNS
resource "aws_lambda_function" "sns_email_process" {
  provider      = aws.mumbai
  architectures = ["arm64"]
  function_name = "sns-email-process-${data.aws_region.mumbai.name}"
  description   = "Lambda Function for Processing SNS Notifications from AWS Events"
  role          = aws_iam_role.lambda_process_sns_role.arn

  filename         = data.archive_file.sns_email_process_lambda_code.output_path
  handler          = "main.lambda_handler"
  package_type     = "Zip"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.sns_email_process_lambda_code.output_base64sha256
  timeout          = 15

  memory_size = 128
  ephemeral_storage {
    size = 512
  }
}

// Spot Change Lambda Function Trigger Permission
resource "aws_lambda_permission" "sns_process_message_spot_permission" {
  provider      = aws.mumbai
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_email_process.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.spot_fleet_change_event_notification_rule.arn
  statement_id  = "AWSEvents_spot_fleet_change_invoke_lambda_process_sns"
}

// Codepipeline Lambda Function Trigger Permission
resource "aws_lambda_permission" "sns_process_message_codepipeline_permission" {
  provider      = aws.mumbai
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_email_process.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codepipeline_event_notification_rule.arn
  statement_id  = "AWSEvents_codepipeline_change_invoke_lambda_process_sns"
}
