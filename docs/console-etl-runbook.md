# AWS Console ETL Runbook

This runbook explains how to run and verify the Terraform-created ETL pipeline from the AWS Console.

Terraform has already created the required infrastructure. Use the AWS Console to operate and verify the ETL workflow; do not manually create duplicate AWS resources.

## 1. Prerequisites

Use the AWS Region:

```text
US East (N. Virginia) - us-east-1
```

Terraform-created resources:

```text
Glue job:       prod-bmw-glue-transform
Glue crawler:   prod-bmw-curated-crawler
Glue database:  prod_bmw_catalog
Glue table:     bike_sharing
Raw bucket:     prod-bmw-s3-raw-cd28c73d
Curated bucket: prod-bmw-s3-curated-cd28c73d
Artifacts:      prod-bmw-s3-artifacts-cd28c73d
Athena workgroup: prod-bmw-athena
```

The uploaded raw dataset is:

```text
s3://prod-bmw-s3-raw-cd28c73d/bike-sharing/bike_hourly.csv
```

## 2. Open the Glue Job

1. Sign in to the AWS Management Console.
2. Select `us-east-1`.
3. Open **AWS Glue**.
4. In the navigation pane, select **ETL jobs**.
5. Open `prod-bmw-glue-transform`.

Do not create a new job. The job was created by Terraform.

## 3. Verify the Glue Job Configuration

Confirm the following settings:

| Setting | Expected value |
|---|---|
| Glue version | `4.0` |
| Worker type | `G.1X` |
| Number of workers | `2` |
| Runtime | Python 3 |
| IAM role | `prod-bmw-data-role` |
| Command | `glueetl` |
| Script location | `s3://prod-bmw-s3-artifacts-cd28c73d/glue/glue_transform.py` |

The job arguments should contain:

```text
--RAW_PATH=s3://prod-bmw-s3-raw-cd28c73d/bike-sharing/
--CURATED_PATH=s3://prod-bmw-s3-curated-cd28c73d/bike-sharing/
```

The script is stored in the artifacts bucket by Terraform. The data role needs `s3:GetObject` access to the `glue/*` path in that bucket.

## 4. Run the Glue ETL Job

1. Select `prod-bmw-glue-transform`.
2. Choose **Run**.
3. Confirm the run.
4. Open the **Runs** tab.
5. Open the latest run.
6. Wait for the status to become:

```text
Succeeded
```

The job reads the raw CSV, converts the columns to typed values, removes invalid records, and writes Parquet output.

If the job fails, open the run details and inspect the error message and CloudWatch logs. The most common permissions are:

- Read raw S3 objects
- Write curated S3 objects
- Read the Glue script from the artifacts bucket
- Use the KMS key
- Write Glue job logs

## 5. Verify Curated S3 Output

1. Open **Amazon S3** in the AWS Console.
2. Open bucket `prod-bmw-s3-curated-cd28c73d`.
3. Open the `bike-sharing/` prefix.

Expected output resembles:

```text
bike-sharing/part-00000-<unique-id>-c000.snappy.parquet
```

The presence of a Parquet file confirms:

```text
Raw S3 CSV -> Glue ETL -> Curated S3 Parquet
```

## 6. Run the Glue Crawler

1. Return to **AWS Glue**.
2. Select **Crawlers**.
3. Open `prod-bmw-curated-crawler`.
4. Confirm its S3 target is:

```text
s3://prod-bmw-s3-curated-cd28c73d/bike-sharing/
```

5. Choose **Run crawler**.
6. Open the crawler history.
7. Wait until the crawler state is `Ready`.
8. Confirm the latest crawl status is `Succeeded`.

The crawler discovers the schema from the Parquet output and updates the Glue Data Catalog.

## 7. Verify the Glue Catalog Table

1. In AWS Glue, open **Data Catalog**.
2. Select **Tables**.
3. Open database `prod_bmw_catalog`.
4. Open table `bike_sharing`.

Expected columns:

```text
timestamp      timestamp
season         int
workingday     int
weather        int
temp           double
humidity       double
windspeed      double
target_count   double
```

This confirms that the curated data is registered for query and downstream ML use.

## 8. Query the Data in Athena

1. Open **Amazon Athena**.
2. Select workgroup `prod-bmw-athena`.
3. Select database `prod_bmw_catalog`.
4. Run this query:

```sql
SELECT *
FROM bike_sharing
LIMIT 10;
```

Expected result: rows containing the eight curated columns.

Run a summary query as an additional check:

```sql
SELECT
  COUNT(*) AS total_rows,
  AVG(target_count) AS average_demand,
  MAX(target_count) AS maximum_demand
FROM bike_sharing;
```

Athena results are configured to use:

```text
s3://prod-bmw-s3-artifacts-cd28c73d/athena-results/
```

## 9. ETL Success Criteria

Mark the ETL stage complete only when all checks pass:

- [ ] Glue job `prod-bmw-glue-transform` is `Succeeded`.
- [ ] A Parquet file exists under the curated S3 `bike-sharing/` prefix.
- [ ] Crawler `prod-bmw-curated-crawler` is `Ready`.
- [ ] Latest crawler run is `Succeeded`.
- [ ] Database `prod_bmw_catalog` exists.
- [ ] Table `bike_sharing` exists.
- [ ] Table schema contains the expected eight columns.
- [ ] Athena sample query succeeds.
- [ ] Athena summary query succeeds.
- [ ] Athena results are stored in the artifacts bucket.

## 10. Data Handoff to ML

After the ETL stage is complete, ML uses this curated path:

```text
s3://prod-bmw-s3-curated-cd28c73d/bike-sharing/
```

The model features are:

```text
season
workingday
weather
temp
humidity
windspeed
```

The prediction target is:

```text
target_count
```

The complete verified data path is:

```text
Raw CSV
  -> Glue ETL
  -> Curated Parquet
  -> Glue Crawler
  -> Glue Catalog table
  -> Athena
  -> ML training input
```

## 11. Console Versus Terraform

Use Terraform for:

- VPC and networking
- S3 buckets
- IAM roles and policies
- Glue job and crawler resources
- Athena workgroup and named query
- SageMaker infrastructure

Use the AWS Console for:

- Starting the Terraform-created Glue job
- Monitoring the Glue job
- Starting the Terraform-created crawler
- Inspecting the Glue Catalog table
- Running Athena queries
- Viewing logs and results

Do not create a second Glue job, bucket, crawler, or database manually in the Console.
