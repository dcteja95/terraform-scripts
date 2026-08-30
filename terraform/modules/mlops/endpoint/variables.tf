variable "name_prefix" {
  type = string
}

variable "ml_role_arn" {
  type = string
}

variable "approved_model_package_arn" {
  type    = string
  default = ""
}

variable "kms_key_arn" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "ml.t3.medium"
}

variable "tags" {
  type = map(string)
}

