variable "name_prefix" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

