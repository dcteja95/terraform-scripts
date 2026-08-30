variable "name_prefix" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "sns_topic_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

