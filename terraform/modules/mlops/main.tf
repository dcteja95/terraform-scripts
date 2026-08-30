module "sagemaker" {
  source      = "./sagemaker"
  name_prefix = var.name_prefix
  tags        = var.tags
}

module "training" {
  source                = "./training"
  name_prefix           = var.name_prefix
  ml_role_arn           = var.ml_role_arn
  curated_bucket_name   = var.curated_bucket_name
  artifacts_bucket_name = var.artifacts_bucket_name
  training_image_uri    = var.training_image_uri
  instance_type         = var.training_instance_type
  enable_training       = var.enable_training
  tags                  = var.tags
}

module "model_registry" {
  source      = "./model-registry"
  name_prefix = module.sagemaker.model_package_group_name
  tags        = var.tags
}

module "endpoint" {
  source                     = "./endpoint"
  name_prefix                = var.name_prefix
  ml_role_arn                = var.ml_role_arn
  approved_model_package_arn = var.approved_model_package_arn
  instance_type              = var.endpoint_instance_type
  kms_key_arn                = var.kms_key_arn
  tags                       = var.tags
}

module "inference" {
  source      = "./inference"
  name_prefix = var.name_prefix
  kms_key_arn = var.kms_key_arn
}

