resource "aws_sagemaker_model_package_group" "this" { model_package_group_name=var.name_prefix tags=var.tags }
