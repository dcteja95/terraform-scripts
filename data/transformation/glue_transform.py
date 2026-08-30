import sys
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import col, to_timestamp

args = getResolvedOptions(sys.argv, ["JOB_NAME", "RAW_PATH", "CURATED_PATH", "TRAINING_PATH"])
sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args["JOB_NAME"], args)

df = spark.read.option("header", "true").csv(args["RAW_PATH"])
clean = (df
    .withColumn("timestamp", to_timestamp(col("timestamp")))
    .withColumn("target_count", col("target_count").cast("double"))
    .withColumn("temp", col("temp").cast("double"))
    .withColumn("humidity", col("humidity").cast("double"))
    .withColumn("windspeed", col("windspeed").cast("double"))
    .withColumn("season", col("season").cast("int"))
    .withColumn("workingday", col("workingday").cast("int"))
    .withColumn("weather", col("weather").cast("int"))
    .filter(col("timestamp").isNotNull())
    .filter(col("target_count").isNotNull())
    .filter(col("target_count") >= 0)
)
clean.write.mode("overwrite").parquet(args["CURATED_PATH"])

training = clean.select(
    "target_count",
    "season",
    "workingday",
    "weather",
    "temp",
    "humidity",
    "windspeed",
)
training.write.mode("overwrite").option("header", "false").csv(args["TRAINING_PATH"])
job.commit()
