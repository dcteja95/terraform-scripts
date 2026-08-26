resource "aws_s3_object" "raw_prefix" { bucket=var.raw_bucket_name key="bike-sharing/" }
