output "role_arn" {
  value = try(aws_iam_role.this[0].arn, null)
}

output "readonly_user_name" {
  value = try(aws_iam_user.readonly[0].name, null)
}

output "readonly_user_access_key_id" {
  value = try(aws_iam_access_key.readonly[0].id, null)
}

output "readonly_user_secret_access_key" {
  value     = try(aws_iam_access_key.readonly[0].secret, null)
  sensitive = true
}

