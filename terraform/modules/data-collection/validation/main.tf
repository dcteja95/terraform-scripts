resource "aws_s3_object" "validation_contract" {
  bucket  = var.artifacts_bucket_name
  key     = "validation/README.txt"
  content = "Data quality contract: timestamp required; target_count must be non-negative; numeric features must be present. The repository contains a deliberate failing test."
}

