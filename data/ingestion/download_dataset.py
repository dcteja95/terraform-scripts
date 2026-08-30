import csv
import io
import urllib.request
import zipfile
from pathlib import Path

URL = "https://archive.ics.uci.edu/static/public/275/bike+sharing+dataset.zip"
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "ingestion"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def main():
    with urllib.request.urlopen(URL, timeout=60) as response:
        payload = response.read()

    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        archive_names = archive.namelist()
        if not archive_names:
            raise RuntimeError("Downloaded archive is empty.")

        csv_name = next((name for name in archive_names if name.endswith("hour.csv")), None)
        if not csv_name:
            raise FileNotFoundError("Could not find hour.csv in the downloaded dataset archive.")

        with archive.open(csv_name) as file_obj:
            rows = list(csv.DictReader(io.TextIOWrapper(file_obj, encoding="utf-8")))

    if not rows:
        raise ValueError("Downloaded dataset contains no rows.")

    selected = []
    for row in rows:
        selected.append(
            {
                "timestamp": f"{row['dteday']} {int(row['hr']):02d}:00:00",
                "season": row["season"],
                "workingday": row["workingday"],
                "weather": row["weathersit"],
                "temp": row["temp"],
                "humidity": row["hum"],
                "windspeed": row["windspeed"],
                "target_count": row["cnt"],
            }
        )

    out_path = OUTPUT_DIR / "bike_hourly.csv"
    fieldnames = selected[0].keys()
    with out_path.open("w", newline="", encoding="utf-8") as file_obj:
        writer = csv.DictWriter(file_obj, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(selected)

    print(f"Dataset saved to: {out_path}")


if __name__ == "__main__":
    main()
