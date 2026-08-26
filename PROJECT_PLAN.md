# Project Plan

## Stage 1 - Terraform Infrastructure

- Reusable infrastructure service modules
- Two-AZ VPC with public/private subnets
- NAT per AZ and S3 Gateway Endpoint
- Raw, curated and artifacts S3
- KMS and IAM
- CloudTrail and Flow Logs
- SNS, Budget, CloudWatch dashboard/alarms
- Evaluator read-only role
- fmt, validate, plan, apply and destroy validation

## Stage 2 - Data Collection

- Public dataset ingestion
- Raw-to-curated Glue transformation
- Glue Catalog and Athena
- Data quality checks
- Deliberate failing validation test

## Stage 3 - MLOps

- SageMaker training
- Model artifacts
- Model registry and approval
- Endpoint deployment
- Inference client
- Evaluation

## Stage 4 - CI/CD and Final Evaluation

- GitHub Actions plan/validate
- Security scanning
- No secrets or state in Git history
- Documentation and architecture diagram
- Cost estimate and assumptions
- Evaluator walkthrough readiness
