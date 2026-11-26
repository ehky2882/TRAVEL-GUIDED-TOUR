#!/usr/bin/env python3
"""Build the Trentino batch from the Dropbox drop: 6 singles for a new studio, Atlas Studio TNO (Trento, with
Rovereto and Avio). Adapted from drafts/veneto-batch1/tools/wire_veneto.py.
Folders are matched by script number. Writes renamed media into <stage>/{audio,images} and merges into Tours.json.

Usage: python3 -I wire_trentino.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-26"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
COUNTRY = "Italy"

PDA_ID = str(uuid.uuid5(NS, "atlas-maker:pda"))
TNO_ID = str(uuid.uuid5(NS, "atlas-maker:tno"))
CODES = {"tno": TNO_ID}

# script no., studio, slug, title, category, tags, radius, caption, city
SPEC = [
 ("22", "tno", "aula-del-simonino", "Aula del Simonino", "history",
  ["Notable Building", "History", "Faith", "Remembrance", "Hidden Gem"], 25,
  "On Via del Simonino in old Trento, facing the house with the painted inscription over its door.", "Trento"),
 ("24", "tno", "castello-del-buonconsiglio", "Buonconsiglio Castle | Castello del Buonconsiglio", "history",
  ["Museum", "History", "Power", "Art", "War", "Iconic Landmark"], 50,
  "On Via Bernardo Clesio, standing back to take in the round tower and the long Renaissance palace.", "Trento"),
 ("82", "tno", "piazza-del-duomo-trento", "Piazza del Duomo, Trento", "culturalHeritage",
  ["Public Square", "History", "Faith", "Architecture", "Iconic Landmark", "Free to Visit", DM,
   "Adamo d'Arogno"], 50,
  "By the Neptune fountain, the cathedral's long stone flank along one side of the square.", "Trento"),
 ("25", "tno", "muse-trento", "MUSE Science Museum | MUSE – Museo delle Scienze", "architecture",
  ["Museum", "Architecture", "Contemporary", "Viewpoint", DM, "Renzo Piano"], 50,
  "On the lawn in front of the museum, looking up at its jagged roof of peaks.", "Trento"),
 ("26", "tno", "mart-rovereto", "Mart | Museo di arte moderna e contemporanea", "visualArt",
  ["Museum", "Art", "Architecture", "Contemporary", DM, "Mario Botta"], 30,
  "On Corso Bettini, at the passage between two old palazzi that leads in under the glass dome.", "Rovereto"),
 ("23", "tno", "castello-di-avio", "Avio Castle | Castello di Avio", "history",
  ["Monument", "History", "Art", "War", "Viewpoint"], 60,
  "At the gate, looking up Monte Vignola to the keep above the terraced vines.", "Avio"),
]

# Coordinates are as supplied. check-coordinates.py: no GROSS; 2 UNVERIFIABLE checked by name against OSM
# (MUSE ~20 m, Via del Simonino 29 m from the street's centre). Avio is 204 m from the castle's OSM point, at
# the gate where the script stands you; Buonconsiglio is 68 m back on Via Clesio, as the script asks.
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
    assert len({s[2] for s in SPEC}) == len(SPEC) == 6
    assert len({s[0] for s in SPEC}) == 6
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
    assert any(m["id"] == PDA_ID for m in data["makers"])
    if not any(m["id"] == TNO_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["id"] == PDA_ID)
        data["makers"].insert(prev + 1, {
            "id": TNO_ID, "displayName": "Atlas Studio TNO", "platform": "dozent", "handle": "atlas.tno",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Trento bureau, down the Adige valley: the prince-bishops' castle and its "
                   "calendar with a month missing; the square where the Council of Trent opened; a house that "
                   "now tells the truth about a 1475 lie; Renzo Piano's mountain of a science museum; Mario "
                   "Botta's hidden dome at Rovereto; and the frescoed castle of Avio among the vines.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker TNO {TNO_ID}")


if __name__ == "__main__":
    main()
