import argparse
import json

import boto3


def parse_args():
    parser = argparse.ArgumentParser(description="Invoke a SageMaker endpoint for a prediction.")
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--season", type=int, default=1)
    parser.add_argument("--workingday", type=int, default=1)
    parser.add_argument("--weather", type=int, default=1)
    parser.add_argument("--temp", type=float, default=0.5)
    parser.add_argument("--humidity", type=float, default=0.5)
    parser.add_argument("--windspeed", type=float, default=0.2)
    return parser.parse_args()


def main():
    args = parse_args()
    client = boto3.client("sagemaker-runtime", region_name=args.region)
    payload = {
        "instances": [[args.season, args.workingday, args.weather, args.temp, args.humidity, args.windspeed]]
    }
    response = client.invoke_endpoint(
        EndpointName=args.endpoint,
        ContentType="application/json",
        Body=json.dumps(payload).encode("utf-8"),
    )
    print(response["Body"].read().decode("utf-8"))


if __name__ == "__main__":
    main()
