import json, subprocess, os, sys
rows=json.load(open("analysis.json"))
ctl={"DcTW0yzsEok","DcLpQ7yOoBU"}
UA="Dozent/1.0 (link-pin tool; +https://dozent.world)"
n=ok=0
for r in rows:
    if r["code"] in ctl or not r["thumb"]: continue
    n+=1; p=f"thumbs/{r['code']}.jpg"
    if os.path.exists(p) and os.path.getsize(p)>5000: ok+=1; continue
    s=subprocess.run(["curl","-sSL","--max-time","40","-A",UA,r["thumb"],"-o",p],capture_output=True)
    sz=os.path.getsize(p) if os.path.exists(p) else 0
    if sz>5000: ok+=1
    else: print("FAIL",r["code"],sz)
print(f"thumbs: {ok}/{n}")
