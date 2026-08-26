variable "name_prefix" { type=string }
variable "region" { type=string }
variable "nat_gateway_ids" { type=list(string) }
variable "sns_topic_arn" { type=string default="" }
variable "tags" { type=map(string) }
