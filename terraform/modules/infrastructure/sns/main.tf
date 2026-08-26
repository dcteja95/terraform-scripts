resource "aws_sns_topic" "alerts" { name="${var.name_prefix}-sns-alerts" tags=merge(var.tags,{Name="${var.name_prefix}-sns-alerts"}) }
resource "aws_sns_topic_subscription" "email" { count=var.alert_email == "" ? 0 : 1 topic_arn=aws_sns_topic.alerts.arn protocol="email" endpoint=var.alert_email }
