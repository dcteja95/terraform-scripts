output "training_job_name" { value=try(aws_sagemaker_training_job.this[0].name, null) }
