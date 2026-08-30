import csv
import sys

REQUIRED_COLUMNS = {
    "timestamp",
    "season",
    "workingday",
    "weather",
    "temp",
    "humidity",
    "windspeed",
    "target_count",
}


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: quality_check.py <csv_path>")

    path = sys.argv[1]
    with open(path, newline="", encoding="utf-8") as file_obj:
        reader = csv.DictReader(file_obj)
        missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"FAIL: missing columns: {sorted(missing)}")

        for line_number, row in enumerate(reader, start=2):
            if not row.get("timestamp"):
                raise SystemExit(f"FAIL: timestamp missing at line {line_number}")

            try:
                target_count = float(row["target_count"])
            except (TypeError, ValueError):
                raise SystemExit(f"FAIL: invalid target_count at line {line_number}")

            if target_count < 0:
                raise SystemExit(f"FAIL: negative target at line {line_number}")

    print("PASS: data quality checks succeeded")


if __name__ == "__main__":
    main()
