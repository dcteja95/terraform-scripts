variable "region" { type = string }
variable "project" { type = string default = "bmw" }
variable "team" { type = string default = "developer" }
variable "environment" { type = string default = "prod" }
variable "vpc_cidr" { type = string default = "10.0.0.0/16" }
variable "alert_email" { type = string default = "" sensitive = true }
variable "monthly_budget_limit" { type = number default = 50 }
variable "enable_budget" { type = bool default = true }
variable "enable_alerting" { type = bool default = true }
variable "evaluator_account_id" { type = string default = "" }
variable "evaluator_external_id" { type = string default = "" sensitive = true }
