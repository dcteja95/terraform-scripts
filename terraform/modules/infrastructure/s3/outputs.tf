output "raw_bucket_name" { value=aws_s3_bucket.raw.bucket }
output "curated_bucket_name" { value=aws_s3_bucket.curated.bucket }
output "artifacts_bucket_name" { value=aws_s3_bucket.artifacts.bucket }
