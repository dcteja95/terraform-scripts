# Assessment Checklist

- [x] Reusable Terraform modules
- [x] Infrastructure / data-collection / mlops composition
- [x] Two-AZ VPC, public/private subnets, NAT per AZ
- [x] S3 Gateway Endpoint
- [x] Raw, curated and artifacts storage zones
- [x] Versioning, encryption, Block Public Access and lifecycle
- [x] Customer-managed KMS
- [x] Separate Data and ML roles
- [x] CloudTrail and VPC Flow Logs
- [x] Budget, SNS and CloudWatch dashboard/alarms
- [x] Evaluator read-only role with external ID inputs
- [x] Raw -> Glue -> curated -> Athena flow
- [x] ML consumes curated storage
- [x] Data-quality failure fixture and validator
- [x] SageMaker training configuration
- [x] Model registry and approved-model endpoint gate
- [x] Inference client
- [x] Terraform CI validation and security scan
- [x] Project plan and architecture documentation

## Still requires execution in the target AWS account

- Terraform init with the real remote backend
- `terraform validate`, plan, apply and destroy
- Upload/run the public dataset flow
- Execute the Glue job/crawler and Athena query
- Run SageMaker training and approve a model package
- Deploy the endpoint and run inference
- Run Checkov and commit the actual scan output/triage
- Confirm evaluator access details
