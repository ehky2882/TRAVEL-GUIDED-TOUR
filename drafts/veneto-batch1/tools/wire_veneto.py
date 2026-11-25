#!/usr/bin/env python3
"""Build the Veneto batch from the Dropbox drop: 3 Venice singles for Atlas Studio VCE and 8 Padua/Veneto
singles for a new studio, Atlas Studio PDA. Adapted from drafts/venice-batch1/tools/wire_venice.py.
Folders are matched by script number. Writes renamed media into <stage>/{audio,images} and merges into Tours.json.

Usage: python3 -I wire_veneto.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-25"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
COUNTRY = "Italy"

VCE_ID = str(uuid.uuid5(NS, "atlas-maker:vce"))
PDA_ID = str(uuid.uuid5(NS, "atlas-maker:pda"))
CODES = {"vce": VCE_ID, "pda": PDA_ID}

# script no., studio, slug, title, category, tags, radius, caption, city
SPEC = [
 ("83", "vce", "palazzo-ducale", "Doge's Palace | Palazzo Ducale", "history",
  ["Civic", "Notable Building", "Power", "History", "Art", "Crime", "Gothic", "Waterfront", "Iconic Landmark", DM,
   "Giovanni Bon", "Bartolomeo Bon"], 50,
  "On the Piazzetta, the lagoon to your right, facing the long arcaded side of the palace.", "Venice"),
 ("41", "vce", "ca-pesaro", "Ca' Pesaro | Galleria Internazionale d'Arte Moderna", "visualArt",
  ["Museum", "Art", "Architecture", "Waterfront", "Baroque", DM, "Baldassare Longhena", "Antonio Gaspari"], 30,
  "From the San Stae landing, looking along the Grand Canal to the great white palace with lion heads.", "Venice"),
 ("40", "vce", "ca-giustinian", "Ca' Giustinian", "history",
  ["Notable Building", "History", "Art", "Gothic", "Waterfront", "Viewpoint", "Free to Visit", "Hidden Gem"], 30,
  "By the San Marco Vallaresso landing, at the Gothic palace where the Grand Canal ends.", "Venice"),
 ("36", "pda", "caffe-pedrocchi", "Caffè Pedrocchi", "foodAndDrink",
  ["Venue", "Food", "History", "Neoclassical", "Iconic Landmark", DM, "Giuseppe Jappelli"], 25,
  "On Via Otto Febbraio, facing the long pale columned front, the neo-Gothic Pedrocchino at one end.", "Padua"),
 ("34", "pda", "palazzo-della-ragione", "Palazzo della Ragione", "architecture",
  ["Civic", "Market", "History", "Art", "Power", "Engineering", "Iconic Landmark", DM, "Giovanni degli Eremitani"], 40,
  "In the great hanging hall above Piazza delle Erbe and Piazza della Frutta, under the ship's-hull roof.", "Padua"),
 ("37", "pda", "casa-del-petrarca", "Petrarch's House | Casa del Petrarca", "literature",
  ["Museum", "Literature", "History", "Hidden Gem"], 25,
  "On Via Valleselle in Arquà Petrarca, at the gate of the stone house on the slope above the village.",
  "Arquà Petrarca"),
 ("32", "pda", "villa-dei-vescovi", "Villa dei Vescovi", "architecture",
  ["Notable Building", "Art", "History", "Food", "Green Escape", "Hidden Gem", DM,
   "Giovanni Maria Falconetto", "Andrea da Valle"], 40,
  "On the drive below, looking up through the vineyard to the villa and its long open loggia.", "Torreglia"),
 ("39", "pda", "villa-pisani", "Villa Pisani", "architecture",
  ["Notable Building", "Museum", "Park", "Art", "Power", "History", "Baroque", "Green Escape", DM,
   "Girolamo Frigimelica", "Francesco Maria Preti"], 50,
  "On the road by the Brenta, facing the long front of the villa across its forecourt.", "Stra"),
 ("43", "pda", "ponte-vecchio-bassano", "Bassano's Old Bridge | Ponte Vecchio", "architecture",
  ["Bridge", "Engineering", "War", "Remembrance", "History", "Iconic Landmark", "Free to Visit", DM,
   "Andrea Palladio"], 40,
  "On the bank of the Brenta at Bassano, facing the long covered timber bridge.", "Bassano del Grappa"),
 ("33", "pda", "madonna-della-corona",
  "Madonna della Corona Sanctuary | Santuario della Madonna della Corona", "sacredSites",
  ["Religious Building", "Faith", "History", "Viewpoint", "Hidden Gem"], 50,
  "On the walkway down from Spiazzi, where the sanctuary comes into view on the cliff face.",
  "Ferrara di Monte Baldo"),
 ("42", "pda", "monte-fontana-secca", "Monte Fontana Secca", "natureAndParks",
  ["Park", "War", "Remembrance", "History", "Food", "Viewpoint", "Green Escape"], 60,
  "On the high pastures of Monte Grappa, by the low stone buildings of the malga.", "Seren del Grappa"),
]

# Coordinates are as supplied. check-coordinates.py: no GROSS; 4 UNVERIFIABLE checked by name against OSM
# (Ca' Pesaro 31 m, Pedrocchi 26 m, Villa Pisani 16 m, Malga Fontana Secca 33 m).
COORD_OVERRIDE = {}
SKIP_IMAGES = {}
TEXT_FIX = {}

# Coordinates are as supplied: Al Timon (15 m from OSM's Fondamenta degli Ormesini 2754) and San Michele
# (60 m from the church, at the landing) were flagged by check-coordinates and checked by hand.
COORD_OVERRIDE = {}
SKIP_IMAGES = {}
TEXT_FIX = {"set into an old wall,.": "set into an old wall."}


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
    assert len({s[2] for s in SPEC}) == len(SPEC) == 11
    assert len({s[0] for s in SPEC}) == 11
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
    assert any(m["id"] == VCE_ID for m in data["makers"])
    if not any(m["id"] == PDA_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["id"] == VCE_ID)
        data["makers"].insert(prev + 1, {
            "id": PDA_ID, "displayName": "Atlas Studio PDA", "platform": "dozent", "handle": "atlas.pda",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Padua bureau, out across the Veneto mainland: the café without doors and a hall "
                   "of justice roofed like an upturned ship; Petrarch's last house and the bishops' villa in the "
                   "Euganean Hills; the grandest villa on the Brenta; Palladio's wooden bridge at Bassano; a "
                   "sanctuary built into a cliff; and the First World War pastures of Monte Grappa.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; makers VCE {VCE_ID}, PDA {PDA_ID}")


if __name__ == "__main__":
    main()
