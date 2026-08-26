module "ingestion" { source="./ingestion" raw_bucket_name=var.raw_bucket_name }
module "glue" { source="./glue" name_prefix=var.name_prefix raw_bucket_name=var.raw_bucket_name curated_bucket_name=var.curated_bucket_name artifacts_bucket_name=var.artifacts_bucket_name data_role_arn=var.data_role_arn tags=var.tags }
module "athena" { source="./athena" name_prefix=var.name_prefix artifacts_bucket_name=var.artifacts_bucket_name tags=var.tags }
module "validation" { source="./validation" artifacts_bucket_name=var.artifacts_bucket_name }
