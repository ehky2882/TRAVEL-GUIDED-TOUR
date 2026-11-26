#!/usr/bin/env python3
"""Build the Piedmont batch from the Dropbox drop: 5 singles for a new studio, Atlas Studio PIE (Piemonte: Manta,
Caravino, Magnano, Verbania, Sant'Ambrogio di Torino). Adapted from drafts/trentino-batch1/tools/wire_trentino.py.
Folders are matched by script number. Writes renamed media into <stage>/{audio,images} and merges into Tours.json.

Usage: python3 -I wire_piedmont.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-26"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
COUNTRY = "Italy"

PREV_ID = str(uuid.uuid5(NS, "atlas-maker:sie"))
PIE_ID = str(uuid.uuid5(NS, "atlas-maker:pie"))
CODES = {"pie": PIE_ID}

# script no., studio, slug, title, category, tags, radius, caption, city
SPEC = [
 ("01", "pie", "castello-della-manta", "Manta Castle | Castello della Manta", "visualArt",
  ["Notable Building", "History", "Art", "Power", "Hidden Gem"], 40,
  "In the castle's inner courtyard at Manta, with Monviso's pointed peak behind you to the west.", "Manta"),
 ("02", "pie", "castello-e-parco-di-masino", "Masino Castle and Park | Castello e Parco di Masino", "history",
  ["Notable Building", "Park", "History", "Power", "Literature", "Green Escape", "Viewpoint"], 60,
  "On the hilltop at Masino, the castle above you and the glacial ridge of the Serra stretching away.", "Caravino"),
 ("03", "pie", "collezione-enrico-villa-flecchia",
  "The Enrico Collection at Villa Flecchia | Collezione Enrico a Villa Flecchia", "visualArt",
  ["Museum", "Art", "Hidden Gem", "Viewpoint"], 30,
  "At Villa Flecchia on the edge of Magnano, the village behind you, looking out over the Ivrea basin.", "Magnano"),
 ("05", "pie", "villa-taranto", "Villa Taranto Botanical Gardens | Giardini Botanici di Villa Taranto", "natureAndParks",
  ["Park", "Green Escape", "History", "Waterfront"], 60,
  "Just inside the gates, the garden paths fanning out down the hillside towards Lake Maggiore.", "Verbania"),
 ("04", "pie", "sacra-di-san-michele", "St Michael's Abbey | Sacra di San Michele", "sacredSites",
  ["Religious Building", "Faith", "History", "Architecture", "Literature", "Iconic Landmark", "Viewpoint"], 50,
  "At the top of the path from the car park, looking up at the abbey rising out of the rock.", "Sant'Ambrogio di Torino"),
]

# Coordinates are as supplied. check-coordinates.py: no GROSS (Manta, Sacra 22 m); 3 UNVERIFIABLE checked by name
# against OSM: Masino ~43 m from the castle node, Villa Flecchia ~25 m, Villa Taranto at the entrance on Via
# Vittorio Veneto (~300 m from the garden's centroid), where the script stands you "just inside the gates".
COORD_OVERRIDE = {}
SKIP_IMAGES = {}
TEXT_FIX = {}


def folder(num):
    pat = f"{num}_*_clean.txt"
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and glob.glob(f"{d}/{pat}")]
    assert len(m) == 1, (num, m)
    return m[0]


def coords(d):
    m = re.search(r"(-?\d+\.\d+),\s*(-?\d+\.\d+)\s*$", d)
    return (round(float(m.group(1)), 7), round(float(m.group(2)), 7))


def paras(path):
    txt = open(path, encoding="utf-8").read().replace("[beat]", "")
    for a, b in TEXT_FIX.items():
        txt = txt.replace(a, b)
    ps = [re.sub(r"\s+", " ", p).strip() for p in re.split(r"\n\s*\n", txt)]
    return [p for p in ps if p][1:]  # drop the title line


def short(s, n=145):
    if len(s) <= n:
        return s
    return s[:n].rsplit(" ", 1)[0].rstrip(",;:") + "…"


def duration(mp3):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", mp3])
    return round(float(out))


def build(spec):
    num, code, slug, title, cat, tags, radius, caption, city = spec
    d = folder(num)
    lat, lon = COORD_OVERRIDE.get(slug, coords(d))
    script = glob.glob(f"{d}/*_clean.txt"); assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    hero = [w for w in webps if w.endswith("_hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if w not in hero
                   and int(re.search(r"_(\d+)o?\.webp$", w).group(1)) not in SKIP_IMAGES.get(slug, ())),
                  key=lambda w: int(re.search(r"_(\d+)o?\.webp$", w).group(1)))
    stem = f"{code}-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"{code}:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": CODES[code],
        "heroImageURL": hero_url,
        "additionalImageURLs": extra,
        "kind": "single",
        "stops": [{
            "id": str(uuid.uuid5(NS, f"atlas-stop:{key}:1")),
            "order": 0,
            "title": title,
            "caption": caption,
            "latitude": lat,
            "longitude": lon,
            "audioURL": f"{BASE}audio/{stem}.mp3",
            "audioDurationSeconds": dur,
            "triggerMode": "geofenced",
            "triggerRadiusMeters": radius,
            "imageURL": hero_url,
            "transcriptText": "\n\n".join(ps),
        }],
        "introAudioURL": None,
        "totalDurationSeconds": dur,
        "walkingDistanceMeters": None,
        "centroidLatitude": lat,
        "centroidLongitude": lon,
        "city": city,
        "country": COUNTRY,
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }


def dist(a, b):
    k = math.cos(math.radians(a[0]))
    return math.hypot((a[0] - b[0]) * 111320, (a[1] - b[1]) * 111320 * k)


def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    assert len({s[2] for s in SPEC}) == len(SPEC) == 5
    assert len({s[0] for s in SPEC}) == 5
    for s in SPEC:
        assert len(s[7]) <= 110, (s[2], len(s[7]))
    new = [build(s) for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    for i, a in enumerate(new):
        for b in new[i + 1:]:
            sa, sb = a["stops"][0], b["stops"][0]
            dd = dist((sa["latitude"], sa["longitude"]), (sb["latitude"], sb["longitude"]))
            if dd < sa["triggerRadiusMeters"] + sb["triggerRadiusMeters"]:
                print(f"OVERLAP {a['title']} / {b['title']}: {dd:.0f} m", file=sys.stderr)
    assert any(m["id"] == PREV_ID for m in data["makers"])
    if not any(m["id"] == PIE_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["id"] == PREV_ID)
        data["makers"].insert(prev + 1, {
            "id": PIE_ID, "displayName": "Atlas Studio PIE", "platform": "dozent", "handle": "atlas.pie",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Piedmont bureau, out from Turin: the abbey on its rock above the Susa Valley; "
                   "a castle hall of nine heroes, nine heroines and a Fountain of Youth at Manta; nine centuries "
                   "of the Valperga at Masino; an architect's landscapes hung facing the landscape at Magnano; "
                   "and a Scotsman's garden on Lake Maggiore.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker PIE {PIE_ID}")


if __name__ == "__main__":
    main()
