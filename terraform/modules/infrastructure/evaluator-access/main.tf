data "aws_iam_policy_document" "assume" {
  count = var.account_id != "" && var.external_id != "" ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.account_id != "" && var.external_id != "" ? 1 : 0
  name               = "${var.name_prefix}-evaluator-readonly"
  assume_role_policy = data.aws_iam_policy_document.assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count      = var.account_id != "" && var.external_id != "" ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Same-account IAM user alternative: read-only access plus permission to invoke the deployed endpoint.
data "aws_caller_identity" "current" {}

locals {
  endpoint_arn = "arn:aws:sagemaker:${var.region}:${data.aws_caller_identity.current.account_id}:endpoint/${var.name_prefix}-endpoint"
}

resource "aws_iam_user" "readonly" {
  count = var.create_readonly_user ? 1 : 0
  name  = "${var.name_prefix}-evaluator"
  tags  = var.tags
}

resource "aws_iam_user_policy_attachment" "readonly" {
  count      = var.create_readonly_user ? 1 : 0
  user       = aws_iam_user.readonly[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "invoke_endpoint" {
  count = var.create_readonly_user ? 1 : 0
  statement {
    actions   = ["sagemaker:InvokeEndpoint"]
    resources = [local.endpoint_arn]
  }
}

resource "aws_iam_user_policy" "invoke_endpoint" {
  count  = var.create_readonly_user ? 1 : 0
  name   = "${var.name_prefix}-evaluator-invoke-endpoint"
  user   = aws_iam_user.readonly[0].name
  policy = data.aws_iam_policy_document.invoke_endpoint[0].json
}

resource "aws_iam_access_key" "readonly" {
  count = var.create_readonly_user ? 1 : 0
  user  = aws_iam_user.readonly[0].name
}

