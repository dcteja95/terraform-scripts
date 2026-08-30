# BMW ML Platform — Implementation Document

## 1. Overview

This document describes the end-to-end implementation of the project: Terraform-managed AWS infrastructure, a data pipeline (raw to curated to Athena), and an MLOps pipeline (training to model approval to endpoint deployment).

---

## 2. Architecture Diagram

<!--
ADD ARCHITECTURE DIAGRAM HERE

Recommended scope for the diagram (matches what is actually deployed):
- VPC with 2 Availability Zones (not 3)
- Public and private subnets per AZ
- NAT Gateway per AZ
- S3 Gateway VPC Endpoint (no KMS interface endpoint is deployed)
- Raw / Curated / Artifacts / Audit S3 buckets (SSE-KMS)
- Data role and ML role (separate IAM roles)
- CloudTrail + VPC Flow Logs (3-day retention)
- Budget + SNS + CloudWatch dashboard/alarms
- Evaluator access: same-account IAM user + cross-account IAM role
- Glue ETL -> Glue Catalog -> Athena
- SageMaker Pipeline -> Training Job -> Model Package (approval) -> Model -> Endpoint Config -> Endpoint -> Inference client

Do not include (not implemented in this project): Route 53, WAF, GuardDuty, Security Hub,
X-Ray, IAM Identity Center/SSO/MFA, Cost Explorer/Trusted Advisor/Cost Anomaly Detection,
DynamoDB, KMS VPC interface endpoint, endpoint auto-scaling/canary deployment.
-->

---

## 3. Project Plan

<!-- ADD OR ADJUST PROJECT PLAN NOTES HERE -->

### Stage 1 — Terraform Infrastructure

| S.No | Task | Pre-requisites | Deliverable | Terraform or Console | Status |
|---|---|---|---|---|---|
| 1 | Reusable Terraform modules | AWS account, Terraform CLI | terraform/modules/ | Terraform | Done |
| 2 | Two-AZ VPC, subnets, NAT, S3 endpoint | VPC CIDR decided | terraform/modules/infrastructure/vpc | Terraform | Done |
| 3 | Raw/curated/artifacts S3 + KMS | KMS key design | terraform/modules/infrastructure/s3, kms | Terraform | Done |
| 4 | Data role and ML role | IAM policy scope | terraform/modules/infrastructure/iam | Terraform | Done |
| 5 | CloudTrail + VPC Flow Logs | Audit bucket | terraform/modules/infrastructure/cloudtrail, flow-logs | Terraform | Done |
| 6 | Budget, SNS, CloudWatch dashboard/alarms | Budget limit decided | terraform/modules/infrastructure/budget, cloudwatch | Terraform | Done |
| 7 | SNS email subscription | Real email address | terraform/modules/infrastructure/sns | Terraform | Done, pending email confirmation |
| 8 | Evaluator read-only IAM user | None | terraform/modules/infrastructure/evaluator-access | Terraform | Done |
| 9 | Evaluator cross-account IAM role | Second AWS account ID | terraform/modules/infrastructure/evaluator-access | Terraform | Done |
| 10 | Glue crawler CloudWatch logging fix | Crawler deployed | terraform/modules/infrastructure/iam | Terraform | Done |
| 11 | terraform init/validate/plan/apply | Remote backend configured | N/A | Terraform | Done |
| 12 | terraform destroy | Confirmed intent | N/A | Terraform | Deferred |

### Stage 2 — Data Collection

| S.No | Task | Pre-requisites | Deliverable | Terraform or Console | Status |
|---|---|---|---|---|---|
| 13 | Upload public dataset to raw bucket | Raw bucket created | data/ingestion/download_dataset.py | Console/CLI | Done |
| 14 | Glue transform job, raw to curated | Glue role + script deployed | data/transformation/glue_transform.py | Terraform + Console | Done |
| 15 | Glue crawler to catalog curated data | Curated data present | Glue database + table | Terraform + Console | Done |
| 16 | Athena query against curated table | Glue Catalog populated | Named query + execution results | Terraform + Console | Done |
| 17 | Data quality validation + failing fixture | Curated schema defined | data/validation/quality_check.py | Script | Done |

### Stage 3 — MLOps

| S.No | Task | Pre-requisites | Deliverable | Terraform or Console | Status |
|---|---|---|---|---|---|
| 18 | SageMaker training pipeline definition | ML role, training image, curated path | terraform/modules/mlops/training | Terraform | Done |
| 19 | Execute training pipeline | Pipeline deployed | Training job Completed | Console/CLI | Done |
| 20 | Register model package | Trained artifact in S3 | Model package (registered) | CLI | Done |
| 21 | Approve model package | Package registered | ModelApprovalStatus Approved | CLI | Done |
| 22 | Create model referencing approved package | Package approved | Model resource | Terraform | Done |
| 23 | Create endpoint config + endpoint | Model created | Endpoint InService | Terraform | Done |
| 24 | Inference client | Endpoint deployed | ml/inference/predict.py | Script | Done |
| 25 | Invoke endpoint, verify prediction | Endpoint InService | Prediction returned | CLI | Done |
| 26 | Evaluation script | Trained model available | ml/evaluation/evaluate.py | Script | Done |

### Stage 4 — CI/CD and Final Evaluation

| S.No | Task | Pre-requisites | Deliverable | Terraform or Console | Status |
|---|---|---|---|---|---|
| 27 | GitHub Actions plan/validate workflow | Repository configured | .github/workflows/terraform-plan.yml | CI config | Done |
| 28 | Security scanning (Checkov) | Checkov installed | checkov-results.json | CI + local | Pending |
| 29 | No secrets/state committed to git | .gitignore configured | .gitignore | Repo hygiene | Done |
| 30 | Documentation + architecture diagram | Project scope finalized | docs/architecture.md, this document | Docs | In progress |
| 31 | Evaluator walkthrough readiness | All prior stages complete | This document | Docs | Done |

---

## 4. Implementation Steps

The implementation was carried out in stages, starting with the Terraform foundation and AWS infrastructure, followed by data processing, MLOps, security, monitoring, and CI/CD.

### 4.1 Terraform Foundation

The project infrastructure was structured using reusable Terraform modules rather than defining all AWS resources directly in a single file.

The Terraform project was organized into separate modules for:

- VPC and networking
- S3
- KMS
- IAM
- CloudTrail
- VPC Flow Logs
- CloudWatch
- SNS
- Budget
- Evaluator access
- Data collection
- MLOps/SageMaker

A separate production environment was maintained under:

```
terraform/environments/prod/
```

The remote Terraform state was configured using an S3 backend so that the infrastructure state is maintained centrally.

The implementation flow was:

```
Terraform Code
     ↓
terraform init
     ↓
terraform validate
     ↓
terraform plan
     ↓
terraform apply
```

The AWS provider and Terraform versions were also defined in the project configuration.

### 4.2 AWS Networking Infrastructure

The AWS infrastructure was implemented using a VPC with two Availability Zones.

> **Architecture note:** The architecture diagram represents three AZs as the target/reference architecture. The current implementation uses two AZs based on the implementation recommendation. The third AZ can be added later if required.

Each Availability Zone contains:

- Public subnet
- Private workload subnet
- Private data subnet

The public subnets contain the NAT Gateway, while workloads and data resources are placed in private subnets.

The implementation also includes an S3 VPC Gateway Endpoint to allow private access to S3 without requiring an internet path for S3 traffic.

The networking module was implemented through Terraform so that the VPC, subnets, route tables, NAT gateways and endpoints can be recreated consistently.

### 4.3 S3 and Data Storage

Separate S3 buckets were created for the different stages of the platform.

The storage flow is:

```
Raw Data
   ↓
Raw S3 Bucket
   ↓
Glue ETL
   ↓
Curated S3 Bucket
   ↓
Glue Catalog
   ↓
Athena
```

An additional artifacts bucket is used for application/ML artifacts, while a dedicated audit bucket is used for logging.

S3 encryption using the customer-managed KMS key was configured for the required buckets.

The implementation also ensures that the buckets are managed through Terraform rather than manually created resources.

### 4.4 KMS and Encryption

A customer-managed AWS KMS key was created using Terraform.

The key is used to support encryption of the required AWS resources and data.

The implementation follows the requirement that data should be encrypted at rest and in transit wherever applicable.

KMS key rotation was enabled, and the key is referenced by the relevant infrastructure modules instead of hard-coding encryption configuration separately in every resource.

### 4.5 IAM Implementation

IAM was implemented using separate roles based on the responsibilities of the platform.

The main roles include:

- **Data/Glue role** – used by AWS Glue to access the required S3 resources and perform ETL operations.
- **ML/SageMaker role** – used by SageMaker training and model-related operations.
- **Terraform deployment role** – used for infrastructure deployment.
- **Evaluator read-only role/user** – provides controlled access for evaluation.
- **Cross-account evaluator role** – provides controlled access from the evaluator AWS account.

The roles follow the least-privilege principle as much as possible, with permissions scoped to the resources required by each service.

The evaluator access implementation also supports cross-account access using an external ID.

### 4.6 CloudTrail and Audit Logging

AWS CloudTrail was implemented through Terraform.

A dedicated audit S3 bucket is used to store CloudTrail logs.

The logging flow is:

```
AWS Account
     ↓
CloudTrail
     ↓
Audit S3 Bucket
     ↓
KMS Encryption
```

CloudTrail configuration is therefore managed as infrastructure and is not hard-coded into the application code.

The audit bucket is separate from the raw, curated and ML artifact buckets.

### 4.7 VPC Flow Logs

VPC Flow Logs were configured to capture network traffic information from the VPC.

The logs are delivered to CloudWatch Logs and retained according to the project requirement.

The current implementation uses the required 3-day retention for CloudTrail and VPC Flow Logs as documented in the project requirements.

### 4.8 Monitoring and Alerting

CloudWatch was implemented for monitoring and operational visibility.

The implementation includes:

- CloudWatch Log Groups
- CloudWatch alarms
- CloudWatch dashboard
- NAT-related monitoring
- SNS notification integration

The alerting flow is:

```
AWS Resource
     ↓
CloudWatch Alarm
     ↓
SNS Topic
     ↓
Email Notification
```

The SNS email subscription requires confirmation from the email inbox before notifications can be delivered.

### 4.9 Cost Management

AWS Budget was configured through Terraform to provide cost monitoring.

The implementation also includes the required FinOps-related configuration represented in the architecture.

The purpose is to provide visibility into infrastructure costs and prevent unexpected spending during the project.

### 4.10 Data Pipeline Implementation

Once the infrastructure was available, the data pipeline was implemented.

**Step 1 – Raw Data**

The public dataset was uploaded to the raw S3 bucket.

The raw data is kept separate from the processed data so that the original input remains available.

```
Dataset
   ↓
S3 Raw
```

**Step 2 – Glue ETL**

An AWS Glue ETL job was implemented to transform the raw dataset.

The Glue job reads the raw data and writes the transformed output to the curated S3 location.

```
S3 Raw
   ↓
Glue ETL
   ↓
S3 Curated
```

**Step 3 – Glue Catalog**

A Glue crawler was configured to discover the curated data and populate the AWS Glue Data Catalog.

This provides the metadata required for querying the data through Athena.

**Step 4 – Athena**

Athena was configured to query the curated dataset through the Glue Catalog.

A sample query was executed to verify that the curated dataset was accessible and queryable.

```
S3 Curated
     ↓
Glue Catalog
     ↓
Athena
     ↓
SQL Query / Results
```

**Step 5 – Data Quality Validation**

A data-quality validation script was also included to verify the expected dataset structure and basic data requirements.

The validation covers items such as:

- Required timestamp
- Non-negative target values
- Required numerical features
- Expected schema

A deliberately failing validation fixture was also included as part of the assessment requirements to demonstrate that the validation mechanism can identify bad input.

### 4.11 SageMaker / MLOps Implementation

After the data pipeline was established, the ML workflow was implemented using SageMaker.

The overall flow is:

```
Curated S3 Data
      ↓
SageMaker Training Job
      ↓
Model Artifact
      ↓
Model Package
      ↓
Model Approval
      ↓
SageMaker Model
      ↓
Endpoint Configuration
      ↓
SageMaker Endpoint
      ↓
Inference Client
```

**Step 1 – Training**

A SageMaker training job was configured to consume the curated dataset from S3.

The training configuration includes:

- Training image
- Training role
- S3 training input
- Model output location
- Instance type
- Runtime configuration

The resulting model artifact is stored in S3.

**Step 2 – Model Registration**

After training, the model artifact was registered in a SageMaker Model Package Group.

This provides a controlled model lifecycle rather than deploying an unregistered model directly.

**Step 3 – Model Approval**

The registered model package was reviewed and its approval status was changed to:

```
Approved
```

Only the approved model package is used for deployment.

**Step 4 – Model Deployment**

The approved model package ARN is provided to Terraform.

Terraform then creates:

- SageMaker Model
- Endpoint Configuration
- SageMaker Endpoint

The deployment therefore follows:

```
Approved Model Package
        ↓
Terraform
        ↓
SageMaker Model
        ↓
Endpoint Configuration
        ↓
Endpoint
```

**Step 5 – Inference**

An inference client was implemented to invoke the SageMaker endpoint.

The request uses the expected feature order:

- season
- workingday
- weather
- temp
- humidity
- windspeed

The endpoint response is then checked to confirm that a prediction is successfully returned.

### 4.12 CI/CD Implementation

GitHub was used as the source-control system for the project.

GitHub Actions was configured to automate Terraform validation and planning.

The intended workflow is:

```
Developer
   ↓
GitHub Repository
   ↓
GitHub Actions
   ↓
Terraform Format / Validate / Plan
   ↓
Security Scan
   ↓
Manual Approval
   ↓
Terraform Apply
```

The Terraform code is maintained in the repository, while sensitive values and Terraform state are excluded from source control.

A `.gitignore` configuration was also included to prevent accidental commits of:

- Terraform state
- Terraform local files
- Credentials
- Sensitive configuration
- Generated files

### 4.13 Security Validation

Security scanning was incorporated into the implementation using Checkov.

The purpose is to identify Terraform configuration issues before infrastructure changes are deployed.

The security validation stage is:

```
Terraform Code
      ↓
Checkov
      ↓
Security Findings
      ↓
Fix / Review
      ↓
Terraform Plan
```

The remaining Checkov findings are to be reviewed and triaged before final project closure.

### 4.14 Evaluator Access

Evaluator access was implemented separately from the application workload.

For same-account evaluation, a read-only evaluator identity is provided with the additional permission required to invoke the SageMaker endpoint.

For cross-account evaluation, an IAM role is created with a trust relationship to the evaluator AWS account.

The evaluator can assume the role using:

```
Evaluator AWS Account
        ↓
STS AssumeRole
        ↓
Evaluator Role
        ↓
Read-only AWS resources
        ↓
SageMaker InvokeEndpoint
```

An external ID is used as an additional control for the cross-account trust relationship.

### 4.15 Final Validation

After implementation, the platform is validated layer by layer rather than testing only the final endpoint.

The validation sequence is:

```
Terraform
   ↓
AWS Infrastructure
   ↓
S3
   ↓
Glue ETL
   ↓
Glue Catalog
   ↓
Athena
   ↓
SageMaker Training
   ↓
Model Registration
   ↓
Model Approval
   ↓
Endpoint Deployment
   ↓
Inference
   ↓
Monitoring / Logging
```

This approach confirms that each component works before moving to the next stage.

### 4.16 Current Implementation Status

At the end of the implementation, the main infrastructure and application components are in place:

| Area | Status |
|---|---|
| Terraform infrastructure | Implemented |
| 2-AZ VPC | Implemented |
| S3 + KMS | Implemented |
| IAM roles | Implemented |
| CloudTrail | Implemented |
| VPC Flow Logs | Implemented |
| CloudWatch monitoring | Implemented |
| SNS alerts | Implemented; email confirmation required |
| Budget | Implemented |
| Data ingestion | Implemented |
| Glue ETL | Implemented |
| Glue Catalog | Implemented |
| Athena | Implemented |
| Data validation | Implemented |
| SageMaker training | Implemented |
| Model registration | Implemented |
| Model approval | Implemented |
| SageMaker endpoint | Implemented |
| Inference | Implemented |
| Evaluator access | Implemented |
| GitHub Actions | Implemented |
| Checkov | Pending final scan/triage |
| Final documentation | In progress |

### Important scope clarification

The following items are shown in the reference architecture but are not part of the current implementation:

- Route 53
- WAF
- GuardDuty
- Security Hub
- X-Ray
- IAM Identity Center/SSO
- MFA enforcement
- Cost Anomaly Detection
- DynamoDB
- KMS interface VPC endpoint
- Endpoint auto-scaling
- Canary deployment

This keeps the implementation document aligned with what was actually built rather than claiming services that were only represented in the architecture.
