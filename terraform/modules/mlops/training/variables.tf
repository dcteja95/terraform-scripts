variable "name_prefix" {
  type = string
}

variable "ml_role_arn" {
  type = string
}

variable "curated_bucket_name" {
  type = string
}

variable "artifacts_bucket_name" {
  type = string
}

variable "training_image_uri" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "ml.m5.large"
}

variable "enable_training" {
  type    = bool
  default = false
}

variable "tags" {
  type = map(string)
}

