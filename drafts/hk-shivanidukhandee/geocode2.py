#!/usr/bin/env python3
"""Multi-strategy geocode. Records WHICH strategy won, so precision is honest.

🔴 countrycodes=hk RETURNS NOTHING — OSM files Hong Kong under `cn`. Viewbox instead.
⚠️ Writes incrementally: the previous single-shot run died at 103/116 and wrote
   no output at all while its launcher reported exit 0.
"""
import json, subprocess, time, urllib.parse, os, re

HK_VIEWBOX="113.83,22.58,114.44,22.15"
UA="Dozent/1.0 (link-pin tool; +https://dozent.world)"
CACHE="geo_cache.json"
cache=json.load(open(CACHE)) if os.path.exists(CACHE) else {}

def nom(q):
    p={"q":q,"format":"json","limit":3,"addressdetails":1,"viewbox":HK_VIEWBOX,"bounded":1}
    url="https://nominatim.openstreetmap.org/search?"+urllib.parse.urlencode(p)
    if url in cache: return cache[url]
    r=subprocess.run(["curl","-sS","--max-time","30","-A",UA,url],capture_output=True)
    try: d=json.loads(r.stdout.decode())
    except Exception: d=[]
    cache[url]=d; json.dump(cache,open(CACHE,"w")); time.sleep(1.1)
    return d

DISTRICTS = ["Sham Shui Po","Tsim Sha Tsui","Mong Kok","Causeway Bay","Sheung Wan","Central",
 "Wan Chai","Wanchai","Yau Ma Tei","North Point","Kowloon City","Sai Kung","Kennedy Town",
 "Tai Koo","Quarry Bay","Aberdeen","Tsuen Wan","Yuen Long","Mui Wo","Tung Chung","Stanley",
 "Hung Hom","Whampoa","Lai Chi Kok","San Po Kong","To Kwa Wan","Kwai Chung","Sai Ying Pun",
 "Sai Wan Ho","Kam Tin","San Tin","Kowloon Bay","Tai Hang","Olympic City","Ma Wan","Tuen Mun",
 "The Peak","Macau","Bandra","Sai Yeung Choi Street","Fa Yuen Street","Fuk Wing Street",
 "Yu Chau Street","Shanghai Street","Peel Street","Upper Lascar Row","Wong Tai Sin","Lam Tsuen"]

def split(v):
    """venue, district"""
    d=None
    for D in DISTRICTS:
        if re.search(r'\b'+re.escape(D)+r'\b', v, re.I): d=D
    core=v
    for sep in [",", " in ", " at ", "("]:
        if sep in core: core=core.split(sep)[0]
    core=re.sub(r'\s*[\(（].*', '', core).strip(" ,-")
    return core, d

def cjk(v):
    m=re.findall(r'[一-鿿]{2,}', v)
    return m[0] if m else None

if __name__=="__main__":
    ven=json.load(open("venues.json"))
    out=[]
    for i,v in enumerate(ven,1):
        raw=v["venue"]; core,dist=split(raw); zh=cjk(raw)
        tried=[]; hits=[]; strat=None
        cands=[]
        if core and dist: cands.append(("venue+district", f"{core}, {dist}, Hong Kong"))
        if core:          cands.append(("venue",          f"{core}, Hong Kong"))
        if core:          cands.append(("venue-bare",      core))
        if zh:            cands.append(("chinese",         zh))
        if dist:          cands.append(("DISTRICT-ONLY",   f"{dist}, Hong Kong"))
        for name,q in cands:
            tried.append(q); hits=nom(q)
            if hits: strat=name; break
        rec=dict(v, core=core, district=dist, strategy=strat, tried=tried,
                 hits=[{"name":h.get("display_name"),"lat":h["lat"],"lon":h["lon"],
                        "cls":h.get("class"),"type":h.get("type")} for h in hits[:2]])
        out.append(rec)
        json.dump(out, open("geo.json","w"), ensure_ascii=False, indent=1)   # incremental
        print(f"{i:3d} {v['code']:12s} {str(strat):14s} {raw[:42]}", flush=True)
    from collections import Counter
    print("STRATEGY:", Counter(r["strategy"] for r in out).most_common())
