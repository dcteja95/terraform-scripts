resource "aws_cloudwatch_log_group" "this" { name="/${var.name_prefix}/vpc-flowlogs" retention_in_days=30 }
data "aws_iam_policy_document" "assume" { statement { principals { type="Service" identifiers=["vpc-flow-logs.amazonaws.com"] } actions=["sts:AssumeRole"] } }
resource "aws_iam_role" "this" { name="${var.name_prefix}-vpc-flowlogs-role" assume_role_policy=data.aws_iam_policy_document.assume.json tags=merge(var.tags,{Name="${var.name_prefix}-vpc-flowlogs-role"}) }
data "aws_iam_policy_document" "policy" { statement { actions=["logs:CreateLogStream","logs:DescribeLogGroups","logs:DescribeLogStreams","logs:PutLogEvents"] resources=["${aws_cloudwatch_log_group.this.arn}:*"] } }
resource "aws_iam_role_policy" "this" { role=aws_iam_role.this.id policy=data.aws_iam_policy_document.policy.json }
resource "aws_flow_log" "this" { vpc_id=var.vpc_id traffic_type="ALL" log_destination_type="cloud-watch-logs" log_destination=aws_cloudwatch_log_group.this.arn iam_role_arn=aws_iam_role.this.arn tags=merge(var.tags,{Name="${var.name_prefix}-vpc-flowlogs"}) }
