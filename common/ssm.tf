resource "aws_ssm_association" "mumbai_ssm_agent_update" {
  provider            = aws.mumbai
  association_name    = "SSM-Agent-Update"
  max_concurrency     = "50"
  max_errors          = "90%"
  name                = "AWS-UpdateSSMAgent"
  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

resource "aws_ssm_association" "ssm_agent_update" {
  association_name    = "SSM-Agent-Update"
  max_concurrency     = "50"
  max_errors          = "90%"
  name                = "AWS-UpdateSSMAgent"
  schedule_expression = "rate(14 days)"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}

resource "aws_ssm_parameter" "mumbai_cloudwatch_agent_config" {
  provider  = aws.mumbai
  data_type = "text"
  name      = "AmazonCloudWatch-agent-config"
  type      = "String"
  value     = file("cw-agent-config.json")
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  data_type = "text"
  name      = "AmazonCloudWatch-agent-config"
  type      = "String"
  value     = file("cw-agent-config.json")
}
