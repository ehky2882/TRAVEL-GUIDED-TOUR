#!/usr/bin/env python3
"""Add Fukuoka script 31, Ocean & Resort Marizon, to Atlas Studio FUK (2026-11-08).
The drop was a single flat zip with no `output <Name> <lat>, <lon>` folder, so the coordinate is not from the drop:
it is the centre of OSM's マリゾン polygon (the deck), with an 80 m geofence covering the ~170 m deck end to end.
Reuses build() from wire_fukuoka.py.

Usage: python3 -I wire_fukuoka_31.py <dir holding the flat drop files> <stage dir>   (run once: refuses colliding ids)"""
import json, os, sys, tempfile, shutil, glob

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
SRC, STAGE = sys.argv[1], sys.argv[2]

# wire_fukuoka.build() expects an `output <Name> <lat>, <lon>` folder: lay the flat files out as one.
tmp = tempfile.mkdtemp()
d = os.path.join(tmp, "output Ocean & Resort Marizon 33.5952679, 130.3511367")
os.makedirs(d)
for f in glob.glob(os.path.join(SRC, "*")):
    shutil.copy(f, d)
sys.argv = [sys.argv[0], tmp, STAGE]
import wire_fukuoka as W  # noqa: E402

SPEC = ("31", "ocean-and-resort-marizon", "Ocean & Resort Marizon | オーシャン&リゾート マリゾン", "architecture",
        ["Waterfront", "Venue", "Architecture", "Maritime", "History", "Contemporary", "Viewpoint", "Free to Visit"],
        80, "On the deck built out over Hakata Bay at Momochi beach, Fukuoka Tower behind you on the shore.")

data = json.load(open(W.CAT, encoding="utf-8"))
t = W.build(SPEC)
assert t["id"] not in {x["id"] for x in data["tours"]}, "id collision"
assert any(m["id"] == W.FUK_ID for m in data["makers"])
data["tours"].append(t)
with open(W.CAT, "wb") as f:
    f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
print("added", t["title"], t["stops"][0]["latitude"], t["stops"][0]["longitude"])
