// singapore Region Notification Topic
resource "aws_sns_topic" "singapore_notification_topic" {
  name = "singapore-sns-topic"
}

// singapore Region Notification Subscriptions
resource "aws_sns_topic_subscription" "singapore_notification_topic_subscriptions" {
  count     = length(var.subscription_emails)
  topic_arn = aws_sns_topic.singapore_notification_topic.arn
  protocol  = "email"
  endpoint  = var.subscription_emails[count.index]
}

// Topic Policy for singapore Staging
resource "aws_sns_topic_policy" "singapore_notification_topic_policy" {
  arn    = aws_sns_topic.singapore_notification_topic.arn
  policy = data.aws_iam_policy_document.singapore_sns_topic_policy.json
}

// policy document
data "aws_iam_policy_document" "singapore_sns_topic_policy" {
  statement {
    actions = ["SNS:Publish"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com", "events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.singapore_notification_topic.arn,
    ]
  }
  version = "2008-10-17"
}
