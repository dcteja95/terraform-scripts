# SageMaker End-to-End Deployment Document

## 1. Purpose

This document describes, step by step, how the SageMaker training and deployment pipeline for this project was implemented, executed, and verified. It covers the full chain from the curated dataset to a live, invokable endpoint.

```
Curated S3 Data
      ↓
SageMaker Pipeline
      ↓
Training Job
      ↓
Model Artifact (S3)
      ↓
Model Package (registered)
      ↓
Model Package Approval
      ↓
SageMaker Model
      ↓
Endpoint Configuration
      ↓
SageMaker Endpoint
      ↓
Inference (invoke-endpoint)
```

---

## 2. Prerequisites

- Terraform infrastructure applied (VPC, S3, KMS, IAM roles) — see `docs/implementation-document.md` section 4.1–4.5.
- Curated training data present in the curated S3 bucket, produced by the Glue ETL job.
- ML execution role available (`prod-bmw-ml-role`), trusted by `sagemaker.amazonaws.com`.
- AWS CLI configured with a profile that has SageMaker permissions.
- Training container image available in ECR (built-in AWS XGBoost image used here).

---

## 3. Component 1 — Training Pipeline (Terraform-managed)

**Resource:** `aws_sagemaker_pipeline` in `terraform/modules/mlops/training/main.tf`

The pipeline is defined as code, not created manually in the console. It contains a single step, `TrainModel`, with the training image, instance type, S3 input/output paths, and hyperparameters expressed as pipeline parameters and arguments.

Key configuration:

| Setting | Value |
|---|---|
| Pipeline name | `prod-bmw-training-pipeline` |
| Role ARN | `arn:aws:iam::713285551865:role/prod-bmw-ml-role` |
| Training image | `683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1` |
| Instance type | `ml.m5.large` |
| Input | `s3://prod-bmw-s3-curated-cd28c73d/bike-sharing-training/` |
| Output | `s3://prod-bmw-s3-artifacts-cd28c73d/training-output/` |
| Hyperparameters | `objective=reg:squarederror`, `num_round=100`, `max_depth=5`, `eta=0.05`, `eval_metric=rmse` |

Creating/updating the pipeline is done through `terraform apply` — no console pipeline builder was used.

---

## 4. Component 2 — Pipeline Execution / Training Job

Creating the pipeline only registers the definition. Running it is a separate, explicit action.

Command used:

```bash
aws sagemaker start-pipeline-execution \
  --pipeline-name prod-bmw-training-pipeline \
  --region us-east-1
```

Verification commands:

```bash
aws sagemaker list-pipeline-executions \
  --pipeline-name prod-bmw-training-pipeline \
  --region us-east-1 \
  --output table
```

```bash
aws sagemaker describe-training-job \
  --training-job-name pipelines-ouf1rl8acgbx-TrainModel-hmvXOeGh0P \
  --region us-east-1
```

Result:

| Execution | Status |
|---|---|
| `ouf1rl8acgbx` | Succeeded |
| `70sk1xqd14gj` | Failed (earlier troubleshooting) |
| `3z8fqn6ert7b` | Failed (earlier troubleshooting) |
| `7mdtt6dhk68x` | Failed (earlier troubleshooting) |

Successful training job: `pipelines-ouf1rl8acgbx-TrainModel-hmvXOeGh0P`, status `Completed`, duration approximately 2 minutes end to end (mostly instance provisioning and image download; actual training was a few seconds due to small dataset size).

Output artifact:
```
s3://prod-bmw-s3-artifacts-cd28c73d/training-output/pipelines-ouf1rl8acgbx-TrainModel-hmvXOeGh0P/output/model.tar.gz
```

---

## 5. Component 3 — Model Package Registration and Approval

The model artifact is not deployed directly. It is first registered as a Model Package, giving it a controlled lifecycle.

### 5.1 Register

```bash
aws sagemaker create-model-package \
  --model-package-name prod-bmw-model-package-fixed \
  --model-package-description "BMW forecasting model package with valid inference metadata" \
  --inference-specification '{
    "Containers": [{
      "Image": "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1",
      "ModelDataUrl": "s3://prod-bmw-s3-artifacts-cd28c73d/training-output/pipelines-ouf1rl8acgbx-TrainModel-hmvXOeGh0P/output/model.tar.gz"
    }],
    "SupportedContentTypes": ["text/csv"],
    "SupportedResponseMIMETypes": ["application/json"],
    "SupportedRealtimeInferenceInstanceTypes": ["ml.m5.large"],
    "SupportedTransformInstanceTypes": ["ml.m5.large"]
  }'
```

### 5.2 Approve

```bash
aws sagemaker update-model-package \
  --model-package-name prod-bmw-model-package-fixed \
  --model-approval-status Approved
```

### 5.3 Verify

```bash
aws sagemaker describe-model-package \
  --model-package-name arn:aws:sagemaker:us-east-1:713285551865:model-package/prod-bmw-model-package-fixed \
  --region us-east-1
```

Confirmed result:

| Field | Value |
|---|---|
| Model package ARN | `arn:aws:sagemaker:us-east-1:713285551865:model-package/prod-bmw-model-package-fixed` |
| Model package status | `Completed` |
| Model approval status | `Approved` |
| Content type | `text/csv` |
| Response MIME type | `application/json` |
| Created by | IAM user `Teja` (audit trail) |

Only a package with `ModelApprovalStatus = Approved` is used for deployment. This is the "approved-model endpoint gate."

---

## 6. Component 4 — Model, Endpoint Configuration, Endpoint (Terraform-managed)

**Resource:** `terraform/modules/mlops/endpoint/main.tf`

```hcl
resource "aws_sagemaker_model" "this" {
  count              = var.approved_model_package_arn == "" ? 0 : 1
  name               = "${var.name_prefix}-model"
  execution_role_arn = var.ml_role_arn
  primary_container {
    model_package_name = var.approved_model_package_arn
  }
}

resource "aws_sagemaker_endpoint_configuration" "this" {
  count = var.approved_model_package_arn == "" ? 0 : 1
  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.this[0].name
    initial_instance_count = 1
    instance_type          = var.instance_type
  }
}

resource "aws_sagemaker_endpoint" "this" {
  count                = var.approved_model_package_arn == "" ? 0 : 1
  endpoint_config_name = aws_sagemaker_endpoint_configuration.this[0].name
}
```

### 6.1 Wiring the approved package into Terraform

```
approved_model_package_arn = "arn:aws:sagemaker:us-east-1:713285551865:model-package/prod-bmw-model-package-fixed"
```
set in `terraform/environments/prod/terraform.tfvars`, then:

```bash
terraform apply
```

### 6.2 Reconciling resources created outside Terraform

During initial debugging, the model/endpoint config/endpoint were briefly created directly via AWS CLI. To bring them under Terraform management without recreating live resources:

```bash
terraform import 'module.mlops.module.endpoint.aws_sagemaker_model.this[0]' prod-bmw-model
terraform import 'module.mlops.module.endpoint.aws_sagemaker_endpoint_configuration.this[0]' prod-bmw-endpoint-config
terraform import 'module.mlops.module.endpoint.aws_sagemaker_endpoint.this[0]' prod-bmw-endpoint
```

After import, `terraform plan` showed the model needed replacement to switch from a raw image/artifact reference to `model_package_name` (the approved package). This was applied:

```bash
terraform apply
```

Result: model recreated to reference the approved package; endpoint remained `InService` throughout (SageMaker endpoints keep serving already-loaded containers independent of the `Model` API object's lifecycle).

### 6.3 Final live state

| Resource | Name | Key detail |
|---|---|---|
| Model | `prod-bmw-model` | Container = Model Package `prod-bmw-model-package-fixed` |
| Endpoint configuration | `prod-bmw-endpoint-config` | Variant `AllTraffic`, `ml.t2.xlarge`, 1 instance |
| Endpoint | `prod-bmw-endpoint` | Status `InService` |

---

## 7. Component 5 — Inference

Feature order (from `ml/training/train.py`):

```
season, workingday, weather, temp, humidity, windspeed
```

### 7.1 Invoke command

```bash
printf '%s\n' '1,0,1,15,50,10' > payload.csv
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name prod-bmw-endpoint \
  --body fileb://payload.csv \
  --content-type text/csv \
  --accept application/json \
  --region us-east-1 output.json
cat output.json
```

### 7.2 Result

```json
{
    "ContentType": "application/json",
    "InvokedProductionVariant": "AllTraffic"
}
{"predictions": [{"score": 116.58187866210938}]}
```

Verified multiple times, both via CloudShell and locally, with consistent results.

---

## 8. Verification Checklist

| Check | Command / Location | Result |
|---|---|---|
| Pipeline exists | `aws sagemaker describe-pipeline --pipeline-name prod-bmw-training-pipeline` | `Active` |
| Execution succeeded | `aws sagemaker list-pipeline-executions` | `Succeeded` (`ouf1rl8acgbx`) |
| Training job completed | `aws sagemaker describe-training-job` | `Completed` |
| Model package approved | `aws sagemaker describe-model-package` | `ModelApprovalStatus: Approved` |
| Model references approved package | `aws sagemaker describe-model` | `ModelPackageName` set, no raw image/artifact fallback |
| Endpoint config correct | `aws sagemaker describe-endpoint-config` | `ml.t2.xlarge`, model `prod-bmw-model` |
| Endpoint live | `aws sagemaker describe-endpoint` | `InService` |
| Inference works | `aws sagemaker-runtime invoke-endpoint` | Prediction returned |
| Terraform in sync | `terraform plan` (in `terraform/environments/prod`) | `No changes` |

---

## 9. Console Navigation Reference

For manually verifying in the AWS Console (SageMaker AI console, region `us-east-1`):

- **Training jobs:** Model training & customization → Training & tuning jobs
- **Model packages:** AWS Marketplace resources → Marketplace model packages (ungrouped packages appear here even though not true marketplace listings)
- **Models:** Deployments & inference → Models
- **Endpoint configurations:** Deployments & inference → Endpoint configurations
- **Endpoints:** Deployments & inference → Endpoints

Note: the visual Pipelines DAG view requires a SageMaker Studio domain. Without a domain, use the CLI (`describe-pipeline`, `list-pipeline-executions`) instead.

---

## 10. Known Limitations

- No endpoint auto-scaling or canary/blue-green deployment configured; single instance, single production variant.
- The model registry group (`prod-bmw-model-group`) exists but the approved package used for deployment is registered ungrouped.
- Batch transform is not used in this project; `SupportedTransformInstanceTypes` is set on the package for completeness only.
