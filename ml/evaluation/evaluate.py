import argparse, json, math
p=argparse.ArgumentParser(); p.add_argument("--actual",type=float,required=True); p.add_argument("--predicted",type=float,required=True); a=p.parse_args()
mae=abs(a.actual-a.predicted); print(json.dumps({"actual":a.actual,"predicted":a.predicted,"mae":mae,"pass":math.isfinite(mae)}))
