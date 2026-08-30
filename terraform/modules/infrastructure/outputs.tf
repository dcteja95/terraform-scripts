output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}

output "raw_bucket_name" {
  value = module.s3.raw_bucket_name
}

output "curated_bucket_name" {
  value = module.s3.curated_bucket_name
}

output "artifacts_bucket_name" {
  value = module.s3.artifacts_bucket_name
}

output "kms_key_arn" {
  value = module.kms.kms_key_arn
}

output "data_role_arn" {
  value = module.iam.data_role_arn
}

output "ml_role_arn" {
  value = module.iam.ml_role_arn
}

output "sns_topic_arn" {
  value = module.sns.topic_arn
}

output "workload_security_group_id" {
  value = module.security_groups.workload_security_group_id
}

output "evaluator_role_arn" {
  value = module.evaluator_access.role_arn
}

output "evaluator_user_name" {
  value = module.evaluator_access.readonly_user_name
}

output "evaluator_access_key_id" {
  value = module.evaluator_access.readonly_user_access_key_id
}

output "evaluator_secret_access_key" {
  value     = module.evaluator_access.readonly_user_secret_access_key
  sensitive = true
}

