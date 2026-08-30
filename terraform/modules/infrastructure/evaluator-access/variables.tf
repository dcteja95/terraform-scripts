variable "name_prefix" {
  type = string
}

variable "account_id" {
  type    = string
  default = ""
}

variable "external_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "region" {
  type = string
}

variable "create_readonly_user" {
  type    = bool
  default = true
}

variable "tags" {
  type = map(string)
}

