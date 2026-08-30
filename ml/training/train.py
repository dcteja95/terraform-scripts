import argparse
import os
from pathlib import Path

import pandas as pd
import xgboost as xgb

FEATURES = ["season", "workingday", "weather", "temp", "humidity", "windspeed"]
TARGET = "target_count"


def parse_args():
    parser = argparse.ArgumentParser(description="Train a bike-sharing demand regressor.")
    parser.add_argument("--train", default=os.environ.get("SM_CHANNEL_TRAIN"))
    parser.add_argument("--model-dir", default=os.environ.get("SM_MODEL_DIR", "/opt/ml/model"))
    return parser.parse_args()


def main():
    args = parse_args()

    if not args.train:
        raise ValueError("Training data directory not provided. Pass --train or set SM_CHANNEL_TRAIN.")

    train_dir = Path(args.train)
    csv_files = sorted(train_dir.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in training directory: {train_dir}")

    df = pd.read_csv(csv_files[0])
    missing = [column for column in FEATURES + [TARGET] if column not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns in training data: {missing}")

    model = xgb.XGBRegressor(
        n_estimators=100,
        max_depth=5,
        learning_rate=0.05,
        objective="reg:squarederror",
    )
    model.fit(df[FEATURES], df[TARGET])

    model_dir = Path(args.model_dir)
    model_dir.mkdir(parents=True, exist_ok=True)
    model_path = model_dir / "model.json"
    model.save_model(str(model_path))
    print(f"Training complete. Model saved to: {model_path}")


if __name__ == "__main__":
    main()
