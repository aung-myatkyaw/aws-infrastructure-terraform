resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "VPN-Server"
  dashboard_body = jsonencode(
    {
      widgets = [
        {
          height = 6
          properties = {
            legend = {
              position = "bottom"
            }
            liveData = false
            metrics = [
              [
                "AWS/EC2",
                "CPUUtilization",
                "InstanceId",
                aws_instance.vpn_server.id
              ],
            ]
            period   = 60
            region   = "ap-southeast-1"
            stacked  = true
            stat     = "Average"
            timezone = "+0630"
            title    = "VPN-Server's CPU Utilization Graph"
            view     = "timeSeries"
          }
          type  = "metric"
          width = 8
          x     = 0
          y     = 0
        },
        {
          height = 6
          properties = {
            metrics = [
              [
                "CWAgent",
                "mem_used_percent",
                "InstanceId",
                aws_instance.vpn_server.id,
                {
                  color = "#ff7f0e"
                },
              ],
            ]
            period   = 60
            region   = "ap-southeast-1"
            stacked  = true
            stat     = "Average"
            timezone = "+0630"
            title    = "VPN-Server's Memory Usage Percent"
            view     = "timeSeries"
          }
          type  = "metric"
          width = 8
          x     = 8
          y     = 0
        },
        {
          height = 6
          properties = {
            metrics = [
              [
                "CWAgent",
                "disk_used_percent",
                "InstanceId",
                aws_instance.vpn_server.id,
                {
                  color = "#2ca02c"
                },
              ],
            ]
            period   = 300
            region   = "ap-southeast-1"
            stacked  = true
            stat     = "Average"
            timezone = "+0630"
            title    = "VPN-Server's Disk Usage Percent"
            view     = "timeSeries"
          }
          type  = "metric"
          width = 8
          x     = 16
          y     = 0
        },
        {
          height = 6
          properties = {
            metrics = [
              [
                "AWS/EC2",
                "CPUCreditBalance",
                "InstanceId",
                aws_instance.vpn_server.id,
                {
                  color = "#17becf"
                },
              ],
            ]
            period    = 300
            region    = "ap-southeast-1"
            sparkline = true
            stacked   = true
            stat      = "Average"
            timezone  = "+0630"
            title     = "VPN-Server's CPU Credit Balance"
            view      = "timeSeries"
          }
          type  = "metric"
          width = 8
          x     = 0
          y     = 6
        },
        {
          height = 6
          properties = {
            metrics = [
              [
                "AWS/EC2",
                "NetworkIn",
                "InstanceId",
                aws_instance.vpn_server.id,
                {
                  color = "#a432a8"
                }
              ],
            ]
            period    = 60
            region    = "ap-southeast-1"
            sparkline = true
            stacked   = true
            stat      = "Average"
            timezone  = "+0630"
            title     = "VPN-Server's Network IN"
            view      = "timeSeries"
          }
          type  = "metric"
          width = 8
          x     = 8
          y     = 6
        },
        {
          height = 6
          properties = {
            metrics = [
              [
                "AWS/EC2",
                "NetworkOut",
                "InstanceId",
                aws_instance.vpn_server.id,
                {
                  color = "#a89932"
                }
              ],
            ]
            period    = 300
            region    = "ap-southeast-1"
            sparkline = true
            stacked   = true
            stat      = "Average"
            timezone  = "+0630"
            title     = "VPN-Server's Network OUT"
            view      = "timeSeries"
          }
          type  = "metric"
          width = 8
          x     = 16
          y     = 6
        }
      ]
    }
  )
}
