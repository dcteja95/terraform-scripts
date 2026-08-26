variable "name_prefix" { type=string }
variable "account_id" { type=string default="" }
variable "external_id" { type=string default="" sensitive=true }
variable "tags" { type=map(string) }
