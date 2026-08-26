resource "random_id" "suffix" { byte_length = 4 }
locals { suffix = random_id.suffix.hex }
resource "aws_s3_bucket" "raw" { bucket = "${var.name_prefix}-s3-raw-${local.suffix}" force_destroy = true tags = merge(var.tags,{Name="${var.name_prefix}-s3-raw"}) }
resource "aws_s3_bucket" "curated" { bucket = "${var.name_prefix}-s3-curated-${local.suffix}" force_destroy = true tags = merge(var.tags,{Name="${var.name_prefix}-s3-curated"}) }
resource "aws_s3_bucket" "artifacts" { bucket = "${var.name_prefix}-s3-artifacts-${local.suffix}" force_destroy = true tags = merge(var.tags,{Name="${var.name_prefix}-s3-artifacts"}) }
resource "aws_s3_bucket_public_access_block" "all" { for_each = { raw=aws_s3_bucket.raw.id, curated=aws_s3_bucket.curated.id, artifacts=aws_s3_bucket.artifacts.id } bucket=each.value block_public_acls=true block_public_policy=true ignore_public_acls=true restrict_public_buckets=true }
resource "aws_s3_bucket_versioning" "all" { for_each = { raw=aws_s3_bucket.raw.id, curated=aws_s3_bucket.curated.id, artifacts=aws_s3_bucket.artifacts.id } bucket=each.value versioning_configuration { status="Enabled" } }
resource "aws_s3_bucket_server_side_encryption_configuration" "all" { for_each = { raw=aws_s3_bucket.raw.id, curated=aws_s3_bucket.curated.id, artifacts=aws_s3_bucket.artifacts.id } bucket=each.value rule { apply_server_side_encryption_by_default { kms_master_key_id=var.kms_key_arn sse_algorithm="aws:kms" } bucket_key_enabled=true } }
resource "aws_s3_bucket_lifecycle_configuration" "raw" { bucket=aws_s3_bucket.raw.id rule { id="raw-retention" status="Enabled" filter {} expiration { days=30 } } }
resource "aws_s3_bucket_lifecycle_configuration" "curated" { bucket=aws_s3_bucket.curated.id rule { id="curated-retention" status="Enabled" filter {} expiration { days=90 } } }
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" { bucket=aws_s3_bucket.artifacts.id rule { id="artifacts-retention" status="Enabled" filter {} expiration { days=180 } } }
