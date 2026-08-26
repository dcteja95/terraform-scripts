resource "aws_s3_object" "script" {
  bucket = var.artifacts_bucket_name
  key = "glue/glue_transform.py"
  source = "${path.root}/../../../data/transformation/glue_transform.py"
  etag = filemd5("${path.root}/../../../data/transformation/glue_transform.py")
}
resource "aws_glue_catalog_database" "this" { name=replace("${var.name_prefix}_catalog","-","_") }
resource "aws_glue_job" "transform" { name="${var.name_prefix}-glue-transform" role_arn=var.data_role_arn glue_version="4.0" worker_type="G.1X" number_of_workers=2 command { name="glueetl" script_location="s3://${var.artifacts_bucket_name}/${aws_s3_object.script.key}" python_version="3" } default_arguments={"--job-language"="python","--RAW_PATH"="s3://${var.raw_bucket_name}/bike-sharing/","--CURATED_PATH"="s3://${var.curated_bucket_name}/bike-sharing/"} tags=var.tags depends_on=[aws_s3_object.script] }
