resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "audit" {
  bucket        = "${var.name_prefix}-s3-audit-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-audit"
  })
}

resource "aws_s3_bucket_public_access_block" "audit" {
  bucket = aws_s3_bucket.audit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit.arn}/AWSLogs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  bucket = aws_s3_bucket.audit.id
  policy = data.aws_iam_policy_document.bucket.json
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    id     = "${var.name_prefix}-cloudtrail-3-day-retention"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days = 3
    }

    noncurrent_version_expiration {
      noncurrent_days = 3
    }
  }
}

data "aws_iam_policy_document" "sns_topic" {
  statement {
    sid    = "AWSCloudTrailSNSPolicy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [var.sns_topic_arn]
  }
}

resource "aws_sns_topic_policy" "cloudtrail" {
  arn    = var.sns_topic_arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.audit.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn
  sns_topic_name                = var.sns_topic_name

  depends_on = [aws_s3_bucket_policy.audit, aws_sns_topic_policy.cloudtrail]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudtrail"
  })
}
