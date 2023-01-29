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

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  data_type = "text"
  name      = "AmazonCloudWatch-agent-config-vpn-server"
  type      = "String"
  value     = file("cw-agent-config-vpn-server.json")
}
