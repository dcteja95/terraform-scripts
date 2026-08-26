module "kms" { source="./kms" name_prefix=var.name_prefix tags=var.tags }
module "s3" { source="./s3" name_prefix=var.name_prefix kms_key_arn=module.kms.kms_key_arn tags=var.tags }
module "vpc" { source="./vpc" name_prefix=var.name_prefix vpc_cidr=var.vpc_cidr region=var.region tags=var.tags }
module "iam" { source="./iam" name_prefix=var.name_prefix raw_bucket_arn="arn:aws:s3:::${module.s3.raw_bucket_name}" curated_bucket_arn="arn:aws:s3:::${module.s3.curated_bucket_name}" artifacts_bucket_arn="arn:aws:s3:::${module.s3.artifacts_bucket_name}" kms_key_arn=module.kms.kms_key_arn tags=var.tags }
module "cloudtrail" { source="./cloudtrail" name_prefix=var.name_prefix tags=var.tags }
module "flow_logs" { source="./flow-logs" name_prefix=var.name_prefix vpc_id=module.vpc.vpc_id tags=var.tags }
module "sns" { source="./sns" name_prefix=var.name_prefix alert_email=var.alert_email tags=var.tags }
module "budget" { source="./budget" name_prefix=var.name_prefix monthly_limit=var.monthly_budget_limit sns_topic_arn=var.enable_alerting ? module.sns.topic_arn : "" enabled=var.enable_budget }
module "cloudwatch" { source="./cloudwatch" name_prefix=var.name_prefix nat_gateway_ids=module.vpc.nat_gateway_ids sns_topic_arn=var.enable_alerting ? module.sns.topic_arn : "" tags=var.tags }
module "security_groups" { source="./security-groups" name_prefix=var.name_prefix vpc_id=module.vpc.vpc_id tags=var.tags }
module "evaluator_access" { source="./evaluator-access" name_prefix=var.name_prefix account_id=var.evaluator_account_id external_id=var.evaluator_external_id tags=var.tags }
