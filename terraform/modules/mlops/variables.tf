variable "name_prefix" { type=string }
variable "region" { type=string }
variable "curated_bucket_name" { type=string }
variable "artifacts_bucket_name" { type=string }
variable "ml_role_arn" { type=string }
variable "kms_key_arn" { type=string }
variable "training_image_uri" { type=string default="" }
variable "training_instance_type" { type=string default="ml.m5.large" }
variable "enable_training" { type=bool default=false }
variable "approved_model_package_arn" { type=string default="" }
variable "endpoint_instance_type" { type=string default="ml.t3.medium" }
variable "tags" { type=map(string) }
