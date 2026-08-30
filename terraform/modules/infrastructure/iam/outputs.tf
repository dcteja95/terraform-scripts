output "data_role_arn" {
  value = aws_iam_role.data.arn
}

output "ml_role_arn" {
  value = aws_iam_role.ml.arn
}

