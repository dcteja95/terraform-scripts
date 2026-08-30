import argparse
import json
import math


def parse_args():
    parser = argparse.ArgumentParser(description="Evaluate a model prediction against a known actual value.")
    parser.add_argument("--actual", type=float, required=True)
    parser.add_argument("--predicted", type=float, required=True)
    return parser.parse_args()


def main():
    args = parse_args()

    if not math.isfinite(args.actual) or not math.isfinite(args.predicted):
        raise ValueError("Actual and predicted values must be finite numbers.")

    mae = abs(args.actual - args.predicted)
    result = {
        "actual": args.actual,
        "predicted": args.predicted,
        "mae": mae,
        "pass": math.isfinite(mae),
    }
    print(json.dumps(result))


if __name__ == "__main__":
    main()
