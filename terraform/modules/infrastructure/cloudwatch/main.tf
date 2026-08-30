resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name_prefix}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      { type = "metric", x = 0, y = 0, width = 24, height = 6, properties = { title = "NAT Gateway Bytes Out", region = var.region, period = 300, stat = "Sum", metrics = [for id in var.nat_gateway_ids : ["AWS/NATGateway", "BytesOutToDestination", "NatGatewayId", id]] } }
    ]
  })
}
resource "aws_cloudwatch_metric_alarm" "nat_bytes" {
  for_each = {
    for idx, nat_gateway_id in var.nat_gateway_ids : tostring(idx) => nat_gateway_id
  }

  alarm_name          = "${var.name_prefix}-alarm-nat-bytes-${each.value}"
  namespace           = "AWS/NATGateway"
  metric_name         = "BytesOutToDestination"
  dimensions          = { NatGatewayId = each.value }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 100000000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.sns_topic_arn == "" ? [] : [var.sns_topic_arn]
}

