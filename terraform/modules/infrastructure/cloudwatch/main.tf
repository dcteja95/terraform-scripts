resource "aws_cloudwatch_dashboard" "this" { dashboard_name="${var.name_prefix}-dashboard" dashboard_body=jsonencode({widgets=[]}) }
