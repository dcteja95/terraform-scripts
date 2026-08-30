locals {
  service_names = {
    vpc        = "${var.name_prefix}-vpc"
    cloudtrail = "${var.name_prefix}-cloudtrail"
    flow_logs  = "${var.name_prefix}-vpc-flowlogs"
  }
}
