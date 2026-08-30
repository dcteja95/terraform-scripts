output "training_job_name" {
  value = local.training_job_name
}

output "training_pipeline_name" {
  value = try(aws_sagemaker_pipeline.training[0].pipeline_name, null)
}

