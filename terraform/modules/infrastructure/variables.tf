variable "name_prefix" { type=string }
variable "region" { type=string }
variable "vpc_cidr" { type=string }
variable "alert_email" { type=string default="" }
variable "monthly_budget_limit" { type=number default=50 }
variable "enable_budget" { type=bool default=true }
variable "enable_alerting" { type=bool default=true }
variable "evaluator_account_id" { type=string default="" }
variable "evaluator_external_id" { type=string default="" sensitive=true }
variable "tags" { type=map(string) }
