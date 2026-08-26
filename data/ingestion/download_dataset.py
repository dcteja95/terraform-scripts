import csv, io, urllib.request, zipfile
from pathlib import Path

URL = "https://archive.ics.uci.edu/static/public/275/bike+sharing+dataset.zip"
out_dir = Path(__file__).resolve().parents[1] / "sample"
out_dir.mkdir(parents=True, exist_ok=True)
with urllib.request.urlopen(URL, timeout=60) as r:
    payload = r.read()
with zipfile.ZipFile(io.BytesIO(payload)) as z:
    with z.open("hour.csv") as f:
        rows = list(csv.DictReader(io.TextIOWrapper(f, encoding="utf-8")))
selected = []
for row in rows:
    selected.append({
        "timestamp": f"{row['dteday']} {int(row['hr']):02d}:00:00",
        "season": row["season"], "workingday": row["workingday"], "weather": row["weathersit"],
        "temp": row["temp"], "humidity": row["hum"], "windspeed": row["windspeed"], "target_count": row["cnt"]
    })
out = out_dir / "bike_hourly.csv"
with out.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=selected[0].keys()); w.writeheader(); w.writerows(selected)
print(out)
