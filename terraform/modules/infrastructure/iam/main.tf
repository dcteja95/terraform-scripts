data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "data_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ml_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "data" {
  name               = "${var.name_prefix}-data-role"
  assume_role_policy = data.aws_iam_policy_document.data_assume.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-data-role" })
}

resource "aws_iam_role" "ml" {
  name               = "${var.name_prefix}-ml-role"
  assume_role_policy = data.aws_iam_policy_document.ml_assume.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-ml-role" })
}

data "aws_iam_policy_document" "data_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [var.raw_bucket_arn, var.curated_bucket_arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["${var.raw_bucket_arn}/*", "${var.curated_bucket_arn}/*"]
  }
  statement {
    actions   = ["s3:DeleteObject"]
    resources = ["${var.curated_bucket_arn}/*"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.artifacts_bucket_arn}/glue/*"]
  }
  statement {
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
  }
  statement {
    actions = ["glue:GetDatabase", "glue:GetDatabases", "glue:GetTable", "glue:GetTables", "glue:CreateTable", "glue:UpdateTable"]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
    ]
  }
  statement {
    actions   = ["glue:CreateCrawler", "glue:GetCrawler", "glue:StartCrawler"]
    resources = ["arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:crawler/${var.name_prefix}-*"]
  }
  statement {
    # GetSecurityConfiguration does not support resource-level restriction in IAM.
    actions   = ["glue:GetSecurityConfiguration", "glue:GetSecurityConfigurations"]
    resources = ["*"]
  }
  statement {
    actions   = ["glue:StartJobRun", "glue:GetJobRun"]
    resources = ["arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.name_prefix}-*"]
  }
  statement {
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws-glue/*",
    ]
  }
}

data "aws_iam_policy_document" "ml_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [var.curated_bucket_arn, var.artifacts_bucket_arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["${var.curated_bucket_arn}/*", "${var.artifacts_bucket_arn}/*"]
  }
  statement {
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
  }
  statement {
    actions   = ["sagemaker:Describe*", "sagemaker:List*"]
    resources = ["arn:aws:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    actions   = ["sagemaker:InvokeEndpoint"]
    resources = ["arn:aws:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:endpoint/${var.name_prefix}-*"]
  }
  statement {
    actions = [
      "sagemaker:CreateTrainingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:StopTrainingJob",
      "sagemaker:AddTags"
    ]
    resources = ["arn:aws:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:training-job/${var.name_prefix}-*"]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ml.arn]
  }
}

resource "aws_iam_role_policy" "data" {
  role   = aws_iam_role.data.id
  name   = "${var.name_prefix}-data-policy"
  policy = data.aws_iam_policy_document.data_policy.json
}

resource "aws_iam_role_policy" "ml" {
  role   = aws_iam_role.ml.id
  name   = "${var.name_prefix}-ml-policy"
  policy = data.aws_iam_policy_document.ml_policy.json
}

