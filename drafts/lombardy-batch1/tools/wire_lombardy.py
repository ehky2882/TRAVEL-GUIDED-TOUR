#!/usr/bin/env python3
"""Build the Lombardy batch from the Dropbox drop: 19 singles. 3 for Atlas Studio MIL (Milan, Segrate) and 16 for a
new regional studio, Atlas Studio LOM (Lombardia). Adapted from drafts/piedmont-batch1/tools/wire_piedmont.py.
Folders are matched by script number. Writes renamed media into <stage>/{audio,images} and merges into Tours.json.

Usage: python3 -I wire_lombardy.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-26"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
COUNTRY = "Italy"

PREV_ID = str(uuid.uuid5(NS, "atlas-maker:pie"))
LOM_ID = str(uuid.uuid5(NS, "atlas-maker:lom"))
MIL_ID = "a875e649-d154-5f8c-b9fc-540691f0960a"
CODES = {"lom": LOM_ID, "mil": MIL_ID}

# script no., studio, slug, title, category, tags, radius, caption, city
SPEC = [
 ("85", "mil", "villa-necchi-campiglio", "Villa Necchi Campiglio", "architecture",
  ["Notable Building", "Museum", "Architecture", "Art Deco", "Modernist", DM, "Piero Portaluppi", "Tomaso Buzzi"], 40,
  "In the garden on Via Mozart, the long blue pool in front of you and the pale house beyond it.", "Milan"),
 ("19", "mil", "san-siro-leonardos-horse",
  "San Siro Racecourse and Leonardo's Horse | Ippodromo San Siro e il Cavallo di Leonardo", "visualArt",
  ["Monument", "Art", "History", "Public Art", "Free to Visit", DM, "Paolo Vietti-Violi"], 40,
  "On Piazzale dello Sport, the bronze horse on its plinth and the racecourse behind it.", "Milan"),
 ("78", "mil", "palazzo-mondadori", "Palazzo Mondadori", "architecture",
  ["Notable Building", "Architecture", "Modernist", "Engineering", DM, "Oscar Niemeyer", "Pietro Porcinai"], 60,
  "Beside the water on Via Arnoldo Mondadori, the glass block hanging inside its white arches.", "Segrate"),
 ("12", "lom", "villa-del-balbianello", "Villa del Balbianello", "natureAndParks",
  ["Notable Building", "Park", "Museum", "History", "Green Escape", "Waterfront", "Viewpoint", "Iconic Landmark"], 50,
  "In the loggia at the tip of the Lavedo peninsula, with the lake on both sides of you.", "Tremezzina"),
 ("16", "lom", "villa-carlotta", "Villa Carlotta", "visualArt",
  ["Notable Building", "Museum", "Park", "Art", "Neoclassical", "Green Escape", "Waterfront"], 50,
  "At the lakeside gates in Tremezzo, the villa above you on its terrace and the lake at your back.", "Tremezzina"),
 ("13", "lom", "la-velarca", "La Velarca", "architecture",
  ["Notable Building", "Architecture", "Modernist", "Maritime", "Waterfront", "Hidden Gem", DM, "BBPR"], 30,
  "On the shore at Ossuccio, by the long, low boat with a timber cabin on its deck.", "Tremezzina"),
 ("11", "lom", "villa-fogazzaro-roi", "Villa Fogazzaro Roi", "literature",
  ["Notable Building", "Museum", "Literature", "Waterfront", "Hidden Gem"], 30,
  "In Oria on Lake Lugano, the villa on the water with its little terrace over the lake.", "Valsolda"),
 ("84", "lom", "buco-del-piombo", "Buco del Piombo", "natureAndParks",
  ["Green Escape", "History", "Hidden Gem", "Viewpoint"], 40,
  "At the foot of the limestone cliff above Erba, the great cave mouth walled across ahead of you.", "Erba"),
 ("08", "lom", "villa-e-collezione-panza", "Villa Panza and the Panza Collection | Villa e Collezione Panza",
  "visualArt", ["Museum", "Art", "Contemporary", "Park", "Green Escape", DM, "Luigi Canonica"], 50,
  "On Piazza Litta on the hill of Biumo, the long, pale villa and its formal garden in front of you.", "Varese"),
 ("07", "lom", "villa-della-porta-bozzolo", "Villa Della Porta Bozzolo", "history",
  ["Notable Building", "Park", "History", "Baroque", "Green Escape", "Hidden Gem"], 50,
  "On the parterre in front of the villa, facing the terraces that climb the hill.", "Casalzuigno"),
 ("10", "lom", "monastero-di-torba", "Torba Monastery | Monastero di Torba", "sacredSites",
  ["Religious Building", "Tower", "History", "Faith", "Art", "Hidden Gem"], 50,
  "In the meadow, with the stone tower, the church and the old monastery all in view.", "Gornate Olona"),
 ("09", "lom", "casa-macchi", "The Macchi House and Shop | Casa ed Emporio Macchi", "hiddenGems",
  ["Museum", "History", "Commerce", "Hidden Gem"], 30,
  "On Piazza Sant'Ambrogio in Morazzone, the house with the little turret below the church tower.", "Morazzone"),
 ("14", "lom", "palazzo-moroni", "Palazzo Moroni", "visualArt",
  ["Notable Building", "Museum", "Art", "Baroque", "Park", "Green Escape", "Viewpoint"], 40,
  "In the courtyard of honour off Via Porta Dipinta, the grotto fountain and the gardens above it.", "Bergamo"),
 ("17", "lom", "ponte-san-michele", "San Michele Bridge | Ponte San Michele", "architecture",
  ["Bridge", "Engineering", "History", "Viewpoint", "Free to Visit", DM, "Jules Röthlisberger"], 60,
  "On the walkway or the bank of the Adda, the iron arch leaping the gorge in front of you.", "Paderno d'Adda"),
 ("20", "lom", "traghetto-di-leonardo", "Leonardo's Ferry | Traghetto di Leonardo", "history",
  ["Waterfront", "Maritime", "Engineering", "History", "Hidden Gem"], 40,
  "At the landing in Imbersago, the cable across the Adda and the wooden ferry hanging from it.", "Imbersago"),
 ("18", "lom", "villa-reale-di-monza", "Royal Villa of Monza | Villa Reale di Monza", "history",
  ["Notable Building", "Museum", "Park", "History", "Power", "Neoclassical", DM, "Giuseppe Piermarini"], 60,
  "In the great courtyard, the palace wrapped round you in a long U and the park beyond.", "Monza"),
 ("15", "lom", "castel-grumello", "Grumello Castle | Castel Grumello", "history",
  ["Notable Building", "History", "Power", "Food", "Viewpoint", "Hidden Gem"], 50,
  "On the rocky spur above Montagna, the twin ruins round you and the vine terraces below.", "Montagna in Valtellina"),
 ("81", "lom", "antica-edicola-mantova", "The Old Newsstand | Antica Edicola dei Giornali", "hiddenGems",
  ["Notable Building", "Commerce", "Gothic", "Public Art", "Free to Visit", "Hidden Gem"], 30,
  "In Piazza Canossa, the little eight-sided kiosk of iron, wood and glass in front of you.", "Mantua"),
 ("21", "lom", "rocca-di-lonato", "Lonato Fortress and the Podestà's House | Rocca di Lonato e Casa del Podestà",
  "history", ["Notable Building", "Library", "Museum", "History", "Power", "War", "Viewpoint"], 60,
  "On the walls of the Rocca, looking north-east over the town towards Lake Garda.", "Lonato del Garda"),
]

# Coordinates are as supplied except three moved onto their subject (contributor OK, 2026-11-26), each to the
# OSM node by name: Mondadori 272 m off across the lake -> Palazzo A; Rocca 160 m off at the Casa del Podesta ->
# the castle; Buco del Piombo 104 m off -> the cave entrance.
COORD_OVERRIDE = {
    "palazzo-mondadori": (45.4718096, 9.2989512),
    "rocca-di-lonato": (45.4629478, 10.4864679),
    "buco-del-piombo": (45.8259406, 9.1989638),
}
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
    assert len({s[2] for s in SPEC}) == len(SPEC) == 19
    assert len({s[0] for s in SPEC}) == 19
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
    assert any(m["id"] == MIL_ID for m in data["makers"])
    if not any(m["id"] == LOM_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["id"] == PREV_ID)
        data["makers"].insert(prev + 1, {
            "id": LOM_ID, "displayName": "Atlas Studio LOM", "platform": "dozent", "handle": "atlas.lom",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Lombardy bureau, out from Milan: villas on the lakes of Como and Lugano and a "
                   "houseboat by the architects of the Torre Velasca; a Roman tower painted by Lombard nuns; rooms "
                   "made of light at Varese; an iron arch over the Adda and the ferry that crosses it with no engine; "
                   "a royal palace at Monza; and a newsstand in Mantua that was asked to move.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker LOM {LOM_ID}")


if __name__ == "__main__":
    main()
