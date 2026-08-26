resource "aws_kms_key" "this" { description="${var.name_prefix} customer managed key" enable_key_rotation=true deletion_window_in_days=7 tags=merge(var.tags,{Name="${var.name_prefix}-kms"}) }
resource "aws_kms_alias" "this" { name="alias/${var.name_prefix}-kms" target_key_id=aws_kms_key.this.key_id }
