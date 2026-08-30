output "endpoint_name" {
  value = try(aws_sagemaker_endpoint.this[0].name, null)
}

