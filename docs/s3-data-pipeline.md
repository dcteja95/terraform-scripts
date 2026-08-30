# S3 Data Pipeline: Bike Sharing Dataset

## 1. Purpose

This document explains the complete data flow for the project, from downloading the public dataset to storing curated data for Athena and ML training.

The pipeline is:

```text
Public UCI dataset
  -> download_dataset.py
  -> Local bike_hourly.csv
  -> Raw S3 CSV
  -> AWS Glue ETL
  -> Curated S3 Parquet
  -> Glue Catalog
  -> Athena and ML training
```

The ML layer must use the curated output produced by Glue. It must not train from a separate copy of the raw dataset.

## 2. Dataset Name and Source

Dataset: **UCI Bike Sharing Dataset**

Source URL used by the ingestion script:

```text
https://archive.ics.uci.edu/static/public/275/bike+sharing+dataset.zip
```

The source contains hourly bike rental observations from the Capital Bikeshare system in Washington, D.C. The selected data covers January 2011 through December 2012.

The project uses the hourly file, `hour.csv`, because the prediction goal is hourly bike demand.

This is public data and does not contain project credentials, AWS secrets or private customer information.

## 3. Data Used by the Project

The ingestion script selects the following fields and writes a smaller project-specific schema:

| Project column | Meaning | Type after Glue |
|---|---|---|
| `timestamp` | Date and hour of the observation | timestamp |
| `season` | Season category: spring, summer, fall or winter | int |
| `workingday` | Whether the day is a working day | int |
| `weather` | Weather condition category | int |
| `temp` | Normalized temperature | double |
| `humidity` | Normalized humidity | double |
| `windspeed` | Normalized wind speed | double |
| `target_count` | Total bikes rented in that hour | double |

The model predicts `target_count` using:

```text
season, workingday, weather, temp, humidity, windspeed
```

The source columns `casual` and `registered` are not used. The combined rental count is used as the prediction target.

## 4. Local Data Preparation

Run these commands from the repository root:

```bash
cd /c/Users/dteja/Downloads/terraform-scripts
python data/ingestion/download_dataset.py
```

The script:

1. Downloads the UCI ZIP archive.
2. Opens the archive in memory.
3. Finds the hourly CSV file.
4. Reads the source rows.
5. Creates the project-specific columns.
6. Builds the timestamp from the source date and hour.
7. Writes the prepared file to:

```text
data/ingestion/bike_hourly.csv
```

The generated file currently contains 17,379 rows and no missing values.

## 5. Local Data Validation

Run the quality check against the prepared data:

```bash
python data/validation/quality_check.py \
  data/ingestion/bike_hourly.csv
```

The expected result is:

```text
PASS: data quality checks succeeded
```

The validator checks that:

- All required columns exist.
- Every row has a timestamp.
- `target_count` is numeric.
- `target_count` is not negative.

The repository also contains an intentional failing fixture:

```bash
python data/validation/quality_check.py \
  data/validation/invalid_dataset.csv
```

That command should fail. The failure demonstrates that invalid data is rejected before it is trusted by the pipeline.

## 6. S3 Buckets Created by Terraform

Terraform creates separate S3 zones:

| Zone | Current bucket | Purpose |
|---|---|---|
| Raw | `prod-bmw-s3-raw-cd28c73d` | Original prepared CSV input |
| Curated | `prod-bmw-s3-curated-cd28c73d` | Cleaned Parquet output |
| Artifacts | `prod-bmw-s3-artifacts-cd28c73d` | Glue scripts, Athena results and ML artifacts |
| Audit | `prod-bmw-s3-audit-b9d77202` | CloudTrail logs |

The generated bucket suffixes are controlled by Terraform. In another account or environment, use Terraform outputs instead of assuming these names.

Get the names dynamically:

```bash
cd terraform/environments/prod
terraform output -raw raw_bucket_name
terraform output -raw curated_bucket_name
terraform output -raw artifacts_bucket_name
cd ../..
```

The data buckets have:

- S3 Block Public Access
- Versioning
- AWS KMS server-side encryption
- S3 Bucket Key
- Lifecycle expiration rules

Lifecycle settings are:

- Raw data: 30 days
- Curated data: 90 days
- Artifacts: 180 days

These settings are suitable for a small demonstration and should be reviewed for a production retention policy.

## 7. Upload the Prepared Data to Raw S3

Upload the validated CSV under the `bike-sharing/` prefix:

```bash
aws s3 cp \
  data/ingestion/bike_hourly.csv \
  s3://prod-bmw-s3-raw-cd28c73d/bike-sharing/bike_hourly.csv \
  --region us-east-1
```

Verify the object:

```bash
aws s3 ls \
  s3://prod-bmw-s3-raw-cd28c73d/bike-sharing/ \
  --region us-east-1
```

Verify encryption and size:

```bash
aws s3api head-object \
  --bucket prod-bmw-s3-raw-cd28c73d \
  --key bike-sharing/bike_hourly.csv \
  --region us-east-1 \
  --query '{Size:ContentLength,Encryption:ServerSideEncryption,ETag:ETag}' \
  --output table
```

The uploaded object was verified with KMS encryption and size `806590` bytes.

## 8. Glue Script and ETL Configuration

The transformation script is:

```text
data/transformation/glue_transform.py
```

Terraform uploads this script to:

```text
s3://prod-bmw-s3-artifacts-cd28c73d/glue/glue_transform.py
```

The Glue job is:

```text
prod-bmw-glue-transform
```

The Terraform configuration uses:

- Glue version: `4.0`
- Worker type: `G.1X`
- Workers: `2`
- Command: `glueetl`
- Python: `3`
- Data role: `prod-bmw-data-role`

The job receives these runtime arguments:

```text
RAW_PATH=s3://prod-bmw-s3-raw-cd28c73d/bike-sharing/
CURATED_PATH=s3://prod-bmw-s3-curated-cd28c73d/bike-sharing/
```

## 9. CSV-to-Parquet Conversion

The Glue script reads the raw CSV with Spark:

```python
df = spark.read.option("header", "true").csv(args["RAW_PATH"])
```

It converts the columns:

```text
timestamp   -> timestamp
season      -> int
workingday  -> int
weather     -> int
temp        -> double
humidity    -> double
windspeed   -> double
target_count -> double
```

It then removes invalid rows:

- Null timestamps
- Null target values
- Negative target values

Finally, it writes the cleaned data as Parquet:

```python
clean.write.mode("overwrite").parquet(args["CURATED_PATH"])
```

Parquet is used because it is columnar, compressed and efficient for Athena queries and ML reads compared with the original CSV.

## 10. Run the Glue Job

Start the job from the VS Code integrated terminal:

```bash
aws glue start-job-run \
  --job-name prod-bmw-glue-transform \
  --region us-east-1
```

Capture the run ID if desired:

```bash
JOB_RUN_ID=$(aws glue start-job-run \
  --job-name prod-bmw-glue-transform \
  --region us-east-1 \
  --query JobRunId \
  --output text)
```

Check the job status:

```bash
aws glue get-job-run \
  --job-name prod-bmw-glue-transform \
  --run-id "$JOB_RUN_ID" \
  --region us-east-1 \
  --query 'JobRun.{State:JobRunState,Error:ErrorMessage}' \
  --output json
```

A successful run has:

```text
JobRunState: SUCCEEDED
```

The Glue data role must be able to:

- Read raw S3 objects
- Write curated S3 objects
- Read the Glue script from `artifacts/glue/*`
- Use the KMS key
- Perform the required Glue operations

The script-read permission was added after the first run failed with an S3 `GetObject` authorization error.

## 11. Verify Curated S3

After the Glue job succeeds:

```bash
aws s3 ls \
  s3://prod-bmw-s3-curated-cd28c73d/bike-sharing/ \
  --recursive \
  --region us-east-1
```

Expected output includes a file similar to:

```text
bike-sharing/part-00000-<id>-c000.snappy.parquet
```

The project successfully produced a curated Parquet file of approximately 172 KB.

## 12. Catalog the Curated Data

Start the Terraform-created crawler:

```bash
aws glue start-crawler \
  --name prod-bmw-curated-crawler \
  --region us-east-1
```

Check its state:

```bash
aws glue get-crawler \
  --name prod-bmw-curated-crawler \
  --region us-east-1 \
  --query 'Crawler.{State:State,LastCrawl:LastCrawl}' \
  --output json
```

Wait for:

```text
State: READY
LastCrawl.Status: SUCCEEDED
```

The crawler creates:

```text
Database: prod_bmw_catalog
Table: bike_sharing
```

The discovered schema matches the curated data columns listed earlier.

## 13. Query with Athena

The Terraform-created Athena workgroup is:

```text
prod-bmw-athena
```

Run a sample query:

```bash
aws athena start-query-execution \
  --query-string "SELECT * FROM bike_sharing LIMIT 10;" \
  --query-execution-context Database=prod_bmw_catalog \
  --work-group prod-bmw-athena \
  --region us-east-1
```

Check the query:

```bash
aws athena get-query-execution \
  --query-execution-id <QUERY_EXECUTION_ID> \
  --region us-east-1 \
  --query 'QueryExecution.{State:Status.State,Output:ResultConfiguration.OutputLocation}' \
  --output json
```

The successful project query returned:

```text
State: SUCCEEDED
```

and wrote results under:

```text
s3://prod-bmw-s3-artifacts-cd28c73d/athena-results/
```

This verifies:

```text
Raw CSV -> Glue ETL -> Curated Parquet -> Glue Catalog -> Athena
```

## 14. ML Handoff

The ML layer consumes the curated output:

```text
s3://prod-bmw-s3-curated-cd28c73d/bike-sharing/
```

The training features are:

```text
season
workingday
weather
temp
humidity
windspeed
```

The target is:

```text
target_count
```

The expected ML sequence is:

1. Read the curated Parquet data.
2. Split data into training and validation sets.
3. Train the XGBoost regression model.
4. Evaluate the model using a holdout set.
5. Save and package the model artifact.
6. Register the model in `prod-bmw-model-group`.
7. Approve the model package.
8. Supply the approved package ARN to Terraform.
9. Deploy the SageMaker endpoint.
10. Invoke it with `ml/inference/predict.py`.

The Glue job preserves the curated Parquet output for Athena and also writes a headerless CSV training prefix derived from that same cleaned dataframe:

```text
s3://<curated-bucket>/bike-sharing-training/
```

The AWS-managed SageMaker XGBoost image consumes this CSV prefix. Its expected row format is target first, followed by the six feature columns. The standard `us-east-1` image configured in the example variables file is:

```text
683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1
```

The Terraform training module now contains an optional SageMaker Pipeline resource. It remains disabled by default and requires a training image URI. After a compatible Parquet-capable training image is supplied and training is enabled, Terraform creates the pipeline; the pipeline execution, model approval and endpoint deployment remain follow-up steps.

## 15. Verification Checklist

- [x] Public UCI Bike Sharing dataset selected and documented.
- [x] `download_dataset.py` created the prepared CSV.
- [x] Prepared CSV passed `quality_check.py`.
- [x] Dataset uploaded to the raw S3 bucket.
- [x] Raw S3 object encryption verified.
- [x] Glue ETL job completed successfully.
- [x] Curated Parquet output verified.
- [x] Glue crawler completed successfully.
- [x] `bike_sharing` Glue Catalog table created.
- [x] Athena query completed successfully.
- [ ] Model trained from the Glue-derived curated training CSV.
- [ ] Model registered and approved.
- [ ] SageMaker endpoint deployed and tested.

## 16. Important Commands Summary

```bash
# Download and validate locally
python data/ingestion/download_dataset.py
python data/validation/quality_check.py data/ingestion/bike_hourly.csv

# Upload to Raw S3
aws s3 cp data/ingestion/bike_hourly.csv \
  s3://prod-bmw-s3-raw-cd28c73d/bike-sharing/bike_hourly.csv \
  --region us-east-1

# Run Glue
aws glue start-job-run \
  --job-name prod-bmw-glue-transform \
  --region us-east-1

# Start crawler
aws glue start-crawler \
  --name prod-bmw-curated-crawler \
  --region us-east-1

# Query Athena
aws athena start-query-execution \
  --query-string "SELECT * FROM bike_sharing LIMIT 10;" \
  --query-execution-context Database=prod_bmw_catalog \
  --work-group prod-bmw-athena \
  --region us-east-1
```
