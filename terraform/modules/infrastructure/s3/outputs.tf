output "raw_bucket_name" { value=aws_s3_bucket.raw.bucket }
output "raw_bucket_arn" { value=aws_s3_bucket.raw.arn }
output "curated_bucket_name" { value=aws_s3_bucket.curated.bucket }
output "curated_bucket_arn" { value=aws_s3_bucket.curated.arn }
output "artifacts_bucket_name" { value=aws_s3_bucket.artifacts.bucket }
output "artifacts_bucket_arn" { value=aws_s3_bucket.artifacts.arn }
