resource "aws_cloudwatch_log_group" "inference" {
  name              = "/${var.name_prefix}/sagemaker/inference"
  retention_in_days = 3
  kms_key_id        = var.kms_key_arn
}

