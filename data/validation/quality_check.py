import csv, sys
required={"timestamp","season","workingday","weather","temp","humidity","windspeed","target_count"}
path=sys.argv[1]
with open(path,newline="",encoding="utf-8") as f:
    r=csv.DictReader(f)
    missing=required-set(r.fieldnames or [])
    if missing: raise SystemExit(f"FAIL: missing columns: {sorted(missing)}")
    for n,row in enumerate(r,start=2):
        if not row["timestamp"]: raise SystemExit(f"FAIL: timestamp missing at line {n}")
        if float(row["target_count"]) < 0: raise SystemExit(f"FAIL: negative target at line {n}")
print("PASS: data quality checks succeeded")
