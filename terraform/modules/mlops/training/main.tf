locals {
  training_job_name    = var.enable_training ? "${var.name_prefix}-training" : null
  training_pipeline_id = var.enable_training && var.training_image_uri != "" ? 1 : 0
}

resource "aws_sagemaker_pipeline" "training" {
  count = local.training_pipeline_id

  pipeline_name         = "${var.name_prefix}-training-pipeline"
  pipeline_display_name = "${var.name_prefix}-training-pipeline"
  role_arn              = var.ml_role_arn
  pipeline_definition = jsonencode({
    Version = "2020-12-01"
    Parameters = [
      {
        Name         = "TrainingImage"
        Type         = "String"
        DefaultValue = var.training_image_uri
      },
      {
        Name         = "TrainingInstanceType"
        Type         = "String"
        DefaultValue = var.instance_type
      }
    ]
    Steps = [
      {
        Name = "TrainModel"
        Type = "Training"
        Arguments = {
          TrainingJobName = {
            "Get" = "Execution.PipelineExecutionId"
          }
          AlgorithmSpecification = {
            TrainingInputMode = "File"
            TrainingImage     = { "Get" = "Parameters.TrainingImage" }
          }
          HyperParameters = {
            objective   = "reg:squarederror"
            num_round   = "100"
            max_depth   = "5"
            eta         = "0.05"
            eval_metric = "rmse"
          }
          InputDataConfig = [
            {
              ChannelName = "train"
              DataSource = {
                S3DataSource = {
                  S3DataDistributionType = "FullyReplicated"
                  S3DataType             = "S3Prefix"
                  S3Uri                  = "s3://${var.curated_bucket_name}/bike-sharing-training/"
                }
              }
              ContentType = "text/csv"
              InputMode   = "File"
            }
          ]
          OutputDataConfig = {
            S3OutputPath = "s3://${var.artifacts_bucket_name}/training-output/"
          }
          ResourceConfig = {
            InstanceCount  = 1
            InstanceType   = { "Get" = "Parameters.TrainingInstanceType" }
            VolumeSizeInGB = 30
          }
          RoleArn = var.ml_role_arn
          StoppingCondition = {
            MaxRuntimeInSeconds = 3600
          }
        }
      }
    ]
  })

  tags = var.tags
}

