resource "aws_sagemaker_model_package_group" "this" {
  model_package_group_name = "${var.name_prefix}-model-group"
  tags                     = var.tags
}

