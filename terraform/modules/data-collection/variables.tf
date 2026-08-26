variable "name_prefix" { type=string }
variable "raw_bucket_name" { type=string }
variable "curated_bucket_name" { type=string }
variable "artifacts_bucket_name" { type=string }
variable "data_role_arn" { type=string }
variable "kms_key_arn" { type=string }
variable "tags" { type=map(string) }
