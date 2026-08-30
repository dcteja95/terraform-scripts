variable "name_prefix" {
  type = string
}

variable "artifacts_bucket_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "table_name" {
  type    = string
  default = "bike_sharing"
}

variable "tags" {
  type = map(string)
}

