import argparse, json, boto3
p=argparse.ArgumentParser(); p.add_argument("--endpoint",required=True); p.add_argument("--region",required=True); p.add_argument("--season",type=int,default=1); p.add_argument("--workingday",type=int,default=1); p.add_argument("--weather",type=int,default=1); p.add_argument("--temp",type=float,default=.5); p.add_argument("--humidity",type=float,default=.5); p.add_argument("--windspeed",type=float,default=.2); a=p.parse_args()
client=boto3.client("sagemaker-runtime",region_name=a.region)
payload={"instances":[[a.season,a.workingday,a.weather,a.temp,a.humidity,a.windspeed]]}
r=client.invoke_endpoint(EndpointName=a.endpoint,ContentType="application/json",Body=json.dumps(payload).encode()); print(r["Body"].read().decode())
