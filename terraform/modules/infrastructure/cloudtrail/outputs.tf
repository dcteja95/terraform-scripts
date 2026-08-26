output "trail_arn" { value=aws_cloudtrail.this.arn }
output "audit_bucket_name" { value=aws_s3_bucket.audit.bucket }
