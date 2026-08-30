# BMW ML Platform

## AWS Hosting & Cost Estimation

The BMW ML Platform is deployed on AWS using Terraform and is currently implemented in the **US East (N. Virginia) – `us-east-1`** region.

The infrastructure uses a two-AZ architecture with private workloads, encrypted S3 storage, AWS Glue for ETL, Amazon Athena for querying, and Amazon SageMaker for model training and inference.

---

## AWS Services Used

| Component | AWS Service | Purpose |
|---|---|---|
| Source Control | GitHub | Source code and Terraform |
| Infrastructure | Terraform | Infrastructure as Code |
| Networking | Amazon VPC | Network isolation |
| Internet Access | NAT Gateway | Outbound access from private subnets |
| Storage | Amazon S3 | Raw, curated, artifacts and audit data |
| Encryption | AWS KMS | Data encryption |
| ETL | AWS Glue | Data transformation |
| Data Catalog | AWS Glue Data Catalog | Dataset metadata |
| Querying | Amazon Athena | SQL queries on curated data |
| ML Training | Amazon SageMaker | Model training |
| Model Registry | SageMaker Model Registry | Model registration and approval |
| Inference | SageMaker Endpoint | Real-time predictions |
| Audit | AWS CloudTrail | AWS API activity |
| Network Logs | VPC Flow Logs | Network monitoring |
| Monitoring | Amazon CloudWatch | Logs, alarms and dashboards |
| Notifications | Amazon SNS | Email alerts |
| Cost Control | AWS Budgets | Budget monitoring |
| Access Control | AWS IAM | Roles and permissions |

---

# AWS Cost Estimation

The following is an estimated monthly cost for the currently implemented infrastructure.

> **Important:** This is an estimated baseline and not a fixed AWS bill. Actual costs depend on data transfer, NAT Gateway data processing, S3 storage, Glue execution time, Athena queries, CloudWatch logs, SageMaker usage and other account-specific usage.

### Cost Assumptions

- AWS Region: `us-east-1`
- 2 Availability Zones
- 2 NAT Gateways
- 2 public IPv4 addresses associated with NAT Gateways
- 1 SageMaker `ml.m5.large` real-time endpoint
- 1 customer-managed KMS key
- 730 hours/month
- Low-volume assessment workload
- No significant NAT Gateway data processing included in the baseline
- No significant S3/Athena/Glue/CloudWatch usage included in the fixed baseline

---

## Estimated Fixed Monthly Cost

| Resource | Quantity | Estimated Rate | Monthly Estimate |
|---|---:|---:|---:|
| NAT Gateway | 2 | ~$0.045/hour | ~$65.70 |
| Public IPv4 | 2 | ~$0.005/hour | ~$7.30 |
| SageMaker `ml.m5.large` Endpoint | 1 | ~$0.115/hour* | ~$83.95 |
| Customer-managed KMS Key | 1 | $1/month | ~$1.00 |
| **Estimated Baseline** | | | **~$157.95/month** |

### Calculation

```text
2 NAT Gateways
$0.045 × 730 hours × 2
= $65.70/month

2 Public IPv4 addresses
$0.005 × 730 hours × 2
= $7.30/month

SageMaker ml.m5.large endpoint
$0.115 × 730 hours
= $83.95/month

1 Customer-managed KMS key

Therefor

2 NAT Gateways       ≈ $65.70
2 Public IPv4        ≈ $7.30
SageMaker endpoint   ≈ $83.95
KMS key              ≈ $1.00
------------------------------------------------
Baseline             ≈ $157.95/month
= $1.00/month
