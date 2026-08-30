resource "aws_athena_workgroup" "this" {
  name = "${var.name_prefix}-athena"
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://${var.artifacts_bucket_name}/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = var.kms_key_arn
      }
    }
  }
  tags = var.tags
}

resource "aws_athena_named_query" "curated_sample" {
  name        = "${var.name_prefix}-curated-sample"
  database    = var.database_name
  workgroup   = aws_athena_workgroup.this.name
  query       = "SELECT * FROM ${var.table_name} LIMIT 10;"
  description = "Sample query against curated data"
}

