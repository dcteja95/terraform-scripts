# BMW AWS ML Platform Take-Home

Terraform implementation organized into reusable infrastructure, data-collection and MLOps modules.

## Structure

```text
terraform/
  modules/
    infrastructure/
    data-collection/
    mlops/
  environments/prod/
data/
ml/
docs/
.github/workflows/
```

## Required tags

The provider applies default tags to every resource through the root environment. Required tags include:

- `Owner`
- `Project = bmw`
- `Team = developer`
- `Environment = prod`
- `CostCenter`

No account IDs, ARNs or bucket names are committed in source.

## Deployment

Configure AWS credentials or GitHub OIDC, copy `terraform/environments/prod/terraform.tfvars.example` to `terraform.tfvars`, then configure the S3 remote-state bucket without committing secrets or state files.

```bash
cd terraform/environments/prod
terraform init \
  -backend-config="bucket=<STATE_BUCKET>" \
  -backend-config="key=bmw/prod/terraform.tfstate" \
  -backend-config="region=<AWS_REGION>" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
terraform fmt -recursive ../..
terraform validate
terraform plan
terraform apply
```

Training and endpoint deployment are intentionally disabled until curated data and an approved model package are available.

## Data flow

Public UCI Bike Sharing dataset -> Raw S3 -> Glue -> Curated S3 -> Athena -> SageMaker training.

ML consumes the curated S3 output rather than another copy of the source dataset.

## Destroy

```bash
terraform destroy
```

Review the plan before destroy. The demonstration buckets use `force_destroy`; production implementations should use retention controls appropriate to the environment.

## Security and cost

S3 Block Public Access, versioning, KMS encryption, separate Data/ML roles, CloudTrail, VPC Flow Logs, evaluator read-only access, budget alerts, CloudWatch dashboard/alarms and CI security scanning are included.
