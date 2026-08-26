import argparse, os, pandas as pd, xgboost as xgb
FEATURES=["season","workingday","weather","temp","humidity","windspeed"]
TARGET="target_count"
p=argparse.ArgumentParser(); p.add_argument("--train",default=os.environ.get("SM_CHANNEL_TRAIN")); p.add_argument("--model-dir",default=os.environ.get("SM_MODEL_DIR","/opt/ml/model")); a=p.parse_args()
files=[os.path.join(a.train,f) for f in os.listdir(a.train) if f.endswith(".csv")]
if not files: raise RuntimeError("No training CSV found")
df=pd.read_csv(files[0]); model=xgb.XGBRegressor(n_estimators=100,max_depth=5,learning_rate=.05,objective="reg:squarederror"); model.fit(df[FEATURES],df[TARGET]); os.makedirs(a.model_dir,exist_ok=True); model.save_model(os.path.join(a.model_dir,"model.json"))
