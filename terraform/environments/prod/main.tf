module "infrastructure" {
  source = "../../modules/infrastructure"
  name_prefix = "${var.environment}-${var.project}"
  region = var.region
  vpc_cidr = var.vpc_cidr
  alert_email = var.alert_email
  monthly_budget_limit = var.monthly_budget_limit
  enable_budget = var.enable_budget
  enable_alerting = var.enable_alerting
  evaluator_account_id = var.evaluator_account_id
  evaluator_external_id = var.evaluator_external_id
  tags = local.common_tags
}

module "data_collection" {
  source = "../../modules/data-collection"
  name_prefix = "${var.environment}-${var.project}"
  raw_bucket_name = module.infrastructure.raw_bucket_name
  curated_bucket_name = module.infrastructure.curated_bucket_name
  artifacts_bucket_name = module.infrastructure.artifacts_bucket_name
  data_role_arn = module.infrastructure.data_role_arn
  kms_key_arn = module.infrastructure.kms_key_arn
  tags = local.common_tags
}

module "mlops" {
  source = "../../modules/mlops"
  name_prefix = "${var.environment}-${var.project}"
  region = var.region
  curated_bucket_name = module.infrastructure.curated_bucket_name
  artifacts_bucket_name = module.infrastructure.artifacts_bucket_name
  ml_role_arn = module.infrastructure.ml_role_arn
  kms_key_arn = module.infrastructure.kms_key_arn
  tags = local.common_tags
}
