#!/usr/bin/env python3
"""Build the Liguria batch from the Dropbox drop: 6 singles for a new studio, Atlas Studio GOA (Genoa and the
Ligurian coast). Adapted from drafts/tuscany-batch1/tools/wire_tuscany.py.
Folders are matched by script number. Writes renamed media into <stage>/{audio,images} and merges into Tours.json.

Usage: python3 -I wire_liguria.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-26"
NS = uuid.NAMESPACE_URL
COUNTRY = "Italy"

GOA_ID = str(uuid.uuid5(NS, "atlas-maker:goa"))
SIE_ID = str(uuid.uuid5(NS, "atlas-maker:sie"))
CODES = {"goa": GOA_ID}
N = 6

# script no., studio, slug, title, category, tags, radius, caption, city
SPEC = [
 ("48", "goa", "villa-rezzola", "Villa Rezzola", "natureAndParks",
  ["Park", "Notable Building", "History", "War", "Green Escape", "Viewpoint"], 50,
  "On the terrace below the villa, facing the Gulf of La Spezia.", "Lerici"),
 ("46", "goa", "abbazia-di-san-fruttuoso", "San Fruttuoso Abbey | Abbazia di San Fruttuoso", "sacredSites",
  ["Religious Building", "Faith", "History", "Maritime", "Hidden Gem"], 50,
  "On the little beach, looking up at the abbey's arches and domed tower.", "Camogli"),
 ("45", "goa", "antica-barberia-giacalone", "Antica Barberia Giacalone", "hiddenGems",
  ["Notable Building", "Commerce", "History", "Hidden Gem"], 25,
  "On Vicolo dei Caprettari, at the small window glittering in the alley.", "Genoa"),
 ("47", "goa", "casa-carbone", "Casa Carbone", "history",
  ["Museum", "Notable Building", "History", "Art", "Hidden Gem"], 25,
  "Under the arcade on Piazza Cordeviola, at the way in to the house.", "Lavagna"),
 ("44", "goa", "casa-e-collezione-laura", "The Laura House and Collection | Casa e Collezione Laura", "visualArt",
  ["Museum", "Art", "History", "Hidden Gem"], 25,
  "On Via Cavour, in front of Villa San Luca, the old Anglican church.", "Ospedaletti"),
 ("49", "goa", "tellaro", "Tellaro", "hiddenGems",
  ["Religious Building", "Waterfront", "History", "Literature", "Maritime", "Viewpoint", "Hidden Gem"], 50,
  "At the church of San Giorgio, on the rock at the very end of the village.", "Lerici"),
]

# check-coordinates.py: no GROSS; Giacalone and Rezzola UNVERIFIABLE (Giacalone ~25 m from Vico Caprettari, kept).
# Moved on the contributor's instruction (2026-11-26), onto the point each script stands you at:
#  Tellaro: supplied point was ~280 m up Via Fiascherino; now OSM's Chiesa di San Giorgio.
#  Villa Rezzola: supplied point was ~105 m away on Via G. Rinaldi; now OSM's Villa Rezzola building.
COORD_OVERRIDE = {"tellaro": (44.0575476, 9.9292254), "villa-rezzola": (44.0859942, 9.9098111)}
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
    assert len({s[2] for s in SPEC}) == len(SPEC) == N
    assert len({s[0] for s in SPEC}) == N
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
    if not any(m["id"] == GOA_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["id"] == SIE_ID)
        data["makers"].insert(prev + 1, {
            "id": GOA_ID, "displayName": "Atlas Studio GOA", "platform": "dozent", "handle": "atlas.goa",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Genoa bureau, along the Ligurian coast: a barber's shop lined with coloured glass "
                   "in the old city's alleys; an abbey reached only by boat or on foot; two family houses left "
                   "exactly as their owners lived in them; a terraced garden above the Gulf of Poets; and a "
                   "village whose church bell, they say, was once rung by an octopus.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker GOA {GOA_ID}")


if __name__ == "__main__":
    main()
