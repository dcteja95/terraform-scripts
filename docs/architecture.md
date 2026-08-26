# Architecture

```mermaid
flowchart TD
  U[Public Dataset] --> R[Raw S3]
  R --> G[Glue ETL]
  G --> C[Curated S3]
  C --> A[Athena]
  C --> T[SageMaker Training]
  T --> AR[Artifacts S3]
  T --> MR[Model Registry]
  MR --> E[SageMaker Endpoint]
  E --> I[Inference Client]

  V[VPC 2 AZ] --> P[Private Subnets]
  P --> N[NAT Gateway per AZ]
  P --> S3E[S3 Gateway Endpoint]
  SEC[KMS + IAM + CloudTrail + Flow Logs] --> R
  SEC --> C
  SEC --> AR
  OBS[SNS + Budget + CloudWatch] --> E
```

## Boundaries

Infrastructure owns shared AWS foundation and security controls. Data Collection owns ingestion, ETL, catalog/query and validation. MLOps owns SageMaker training, model lifecycle, deployment and inference.

The key data dependency is `Raw S3 -> Glue -> Curated S3 -> MLOps`; MLOps does not ingest a second copy of the source dataset.
