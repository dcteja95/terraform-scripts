resource "aws_s3_object" "script" {
  bucket = var.artifacts_bucket_name
  key    = "glue/glue_transform.py"
  source = "${path.root}/../../../data/transformation/glue_transform.py"
  etag   = filemd5("${path.root}/../../../data/transformation/glue_transform.py")
}
resource "aws_glue_catalog_database" "this" {
  name = replace("${var.name_prefix}_catalog", "-", "_")
}

resource "aws_glue_security_configuration" "this" {
  name = "${var.name_prefix}-glue-secconf"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = var.kms_key_arn
    }
    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = var.kms_key_arn
    }
    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = var.kms_key_arn
    }
  }
}

resource "aws_glue_job" "transform" {
  name                   = "${var.name_prefix}-glue-transform"
  role_arn               = var.data_role_arn
  glue_version           = "4.0"
  worker_type            = "G.1X"
  number_of_workers      = 2
  security_configuration = aws_glue_security_configuration.this.name
  command {
    name            = "glueetl"
    script_location = "s3://${var.artifacts_bucket_name}/${aws_s3_object.script.key}"
    python_version  = "3"
  }
  default_arguments = { "--job-language" = "python", "--RAW_PATH" = "s3://${var.raw_bucket_name}/bike-sharing/", "--CURATED_PATH" = "s3://${var.curated_bucket_name}/bike-sharing/", "--TRAINING_PATH" = "s3://${var.curated_bucket_name}/bike-sharing-training/" }
  tags              = var.tags
  depends_on        = [aws_s3_object.script]
}

resource "aws_glue_crawler" "curated" {
  name                   = "${var.name_prefix}-curated-crawler"
  role                   = var.data_role_arn
  database_name          = aws_glue_catalog_database.this.name
  security_configuration = aws_glue_security_configuration.this.name
  s3_target {
    path = "s3://${var.curated_bucket_name}/bike-sharing/"
  }
}

