#!/usr/bin/env python3
"""Build the Italy regions batch from the Dropbox drop: 16 singles across nine regions. Six new studios (AOT Aosta
Valley, TRS Friuli, PEG Umbria, SUF Calabria, RAN Ravenna, AOI Marche) plus singles for three existing ones (NAP, BRI,
ROM), on the contributor's choice ("codes fine"). Adapted from drafts/sardinia-batch1/tools/wire_sardinia.py.
Folders are matched by script number. Writes renamed media into <stage>/{audio,images} and merges into Tours.json.

Usage: python3 -I wire_italy_regions.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-27"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
COUNTRY = "Italy"


def mid(code):
    return str(uuid.uuid5(NS, f"atlas-maker:{code}"))


PREV_ID = mid("cag")  # new studios go in after CAG, in this order
NEW_MAKERS = [
    ("aot", "Atlas Studio AOT", "🇮🇹",
     "Atlas Studio's Aosta Valley bureau: Queen Margherita's five-towered summer house above Gressoney, with Monte "
     "Rosa behind it and its kitchens thirty metres away, connected by an underground railway."),
    ("trs", "Atlas Studio TRS", "🇮🇹",
     "Atlas Studio's Friuli bureau, out from Trieste: the largest early Christian mosaic floor in the West at Aquileia, "
     "and the Devil's Bridge at Cividale, blown up in 1917 and rebuilt exactly as it was."),
    ("peg", "Atlas Studio PEG", "🇮🇹",
     "Atlas Studio's Umbria bureau, out from Perugia: the wood below the Basilica of Saint Francis in Assisi, down to "
     "Pistoletto's Third Paradise, and Spoleto's Ponte delle Torri, an aqueduct eighty metres above a gorge."),
    ("suf", "Atlas Studio SUF", "🇮🇹",
     "Atlas Studio's Calabria bureau, out from Lamezia: the Giants of the Sila, laricio pines three and a half "
     "centuries old, saved by the family that planted them."),
    ("ran", "Atlas Studio RAN", "🇮🇹",
     "Atlas Studio's Ravenna bureau: Theodoric's tomb under its single stone dome, the palace that was never his, and "
     "the green mosaic meadow of Sant'Apollinare in Classe."),
    ("aoi", "Atlas Studio AOI", "🇮🇹",
     "Atlas Studio's Marche bureau, out from Ancona: the garden in Recanati where Leopardi wrote L'infinito, and "
     "Senigallia's Rotonda a Mare, a pavilion standing out in the Adriatic."),
]
CODES = {c: mid(c) for c in ["aot", "trs", "peg", "suf", "ran", "aoi", "nap", "bri", "rom"]}

# script no., studio, slug, title, category, tags, radius, caption, city
SPEC = [
 ("06", "aot", "castel-savoia", "Savoy Castle | Castel Savoia", "history",
  ["Notable Building", "History", "Power", "Viewpoint", DM, "Emilio Stramucci"], 50,
  "On the drive below the castle, far enough back to take in all five towers at once.", "Gressoney-Saint-Jean"),
 ("60", "nap", "baia-di-ieranto", "Ieranto Bay | Baia di Ieranto", "natureAndParks",
  ["Waterfront", "Maritime", "History", "Green Escape", "Viewpoint", "Hidden Gem"], 80,
  "At the bottom of the path from Nerano, above the bay, facing the Faraglioni of Capri.", "Massa Lubrense"),
 ("28", "trs", "basilica-di-aquileia", "Aquileia Basilica | Basilica di Aquileia", "sacredSites",
  ["Religious Building", "Faith", "Art", "History", "Iconic Landmark"], 50,
  "Inside the basilica, on the walkway above the fourth-century mosaic floor.", "Aquileia"),
 ("54", "peg", "bosco-di-san-francesco", "St Francis's Wood | Bosco di San Francesco", "natureAndParks",
  ["Park", "Green Escape", "Faith", "Art", "Public Art", "Hidden Gem"], 60,
  "On the lawn of the Upper Basilica square, by the door in the wall that leads down into the wood.", "Assisi"),
 ("68", "bri", "castello-tramontano", "Tramontano Castle | Castello Tramontano", "history",
  ["Monument", "History", "Power", "Crime", "Viewpoint"], 50,
  "On the Lapillo hill above the old town, facing the round keep and its two side towers.", "Matera"),
 ("61", "nap", "duomo-di-salerno", "Salerno Cathedral | Duomo di Salerno", "sacredSites",
  ["Religious Building", "Faith", "Art", "History", "Architecture", "Iconic Landmark", DM, "Domenico Fontana"], 50,
  "Through the Lion Gate, in the arcaded courtyard in front of the cathedral.", "Salerno"),
 ("69", "suf", "giganti-della-sila", "The Giants of the Sila | I Giganti della Sila", "natureAndParks",
  ["Park", "Green Escape", "History", "Commerce", "Hidden Gem"], 60,
  "At the edge of the wood near Croce di Magara, where the path leads in among the pines.", "Spezzano della Sila"),
 ("29", "ran", "mausoleo-di-teodorico", "Mausoleum of Theodoric | Mausoleo di Teodorico", "history",
  ["Monument", "History", "Power", "Engineering", "Architecture", "Iconic Landmark"], 50,
  "On the lawn outside the tomb, where you can see both storeys and the single-stone dome.", "Ravenna"),
 ("56", "aoi", "orto-sul-colle-dell-infinito", "Garden on the Hill of the Infinite | Orto sul Colle dell'Infinito",
  "literature", ["Park", "Literature", "Viewpoint", "Green Escape", "Hidden Gem"], 50,
  "In the old nuns' garden beside Santo Stefano, at the edge looking out over the hills.", "Recanati"),
 ("31", "ran", "palazzo-di-teodorico", "Palace of Theodoric | Palazzo di Teodorico", "history",
  ["Notable Building", "History", "Architecture", "Free to Visit", "Hidden Gem"], 40,
  "On Via di Roma at the corner of Via Alberoni, facing the tall brick facade.", "Ravenna"),
 ("59", "rom", "parco-degli-acquedotti", "Park of the Aqueducts | Parco degli Acquedotti", "natureAndParks",
  ["Park", "Engineering", "History", "Green Escape", "Free to Visit", "Viewpoint"], 80,
  "In the open meadow, looking along the arches of the Aqua Claudia towards the city.", "Rome"),
 ("27", "trs", "ponte-del-diavolo-cividale", "Devil's Bridge | Ponte del Diavolo", "history",
  ["Bridge", "Engineering", "War", "History", "Free to Visit", "Viewpoint"], 40,
  "On the bridge, or the bank below it, looking down at the green Natisone.", "Cividale del Friuli"),
 ("55", "peg", "ponte-delle-torri", "Bridge of Towers | Ponte delle Torri", "architecture",
  ["Bridge", "Engineering", "History", "Iconic Landmark", "Viewpoint", "Free to Visit"], 50,
  "At the town end of the bridge, below the Rocca, looking across the gorge to Monteluco.", "Spoleto"),
 ("57", "aoi", "rotonda-a-mare", "Rotonda a Mare", "architecture",
  ["Notable Building", "Waterfront", "Venue", "Architecture", "Iconic Landmark"], 40,
  "At the end of the pier from the seafront, where it reaches the round pavilion.", "Senigallia"),
 ("30", "ran", "sant-apollinare-in-classe", "Basilica of Sant'Apollinare in Classe | Sant'Apollinare in Classe",
  "sacredSites", ["Religious Building", "Faith", "Art", "History", "Iconic Landmark"], 50,
  "Down the nave between the marble columns, facing the green mosaic of the apse.", "Ravenna"),
 ("58", "rom", "villa-gregoriana", "Villa Gregoriana", "natureAndParks",
  ["Park", "Engineering", "History", "Green Escape", "Viewpoint"], 60,
  "At the entrance on Largo Sant'Angelo, looking down into the gorge of the Aniene.", "Tivoli"),
]

# Bosco di San Francesco: the supplied point was Santa Croce, mid-walk, ~1.1 km from where the script starts. Moved to
# the north edge of the Upper Basilica lawn (OSM "Piazza Superiore di San Francesco"), where FAI's entrance door is in
# the perimeter wall; the 60 m radius covers the square. On the contributor's OK ("move assisi").
COORD_OVERRIDE = {
    "bosco-di-san-francesco": (43.0747, 12.6071),
}
# Ponte delle Torri: the delivered hero is Gravina in Puglia's Ponte Acquedotto, not Spoleto ("take out
# ponte-delle-torri_hero ... use ponte-delle-torri_2 as hero"). Ieranto _4 is Marina del Cantone ("drop ieranto_4").
DROP_HERO = {"ponte-delle-torri": 2}
SKIP_IMAGES = {"baia-di-ieranto": {4}}
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


def num_of(w):
    return int(re.search(r"_(\d+)o?\.webp$", w).group(1))


def build(spec):
    num, code, slug, title, cat, tags, radius, caption, city = spec
    d = folder(num)
    lat, lon = COORD_OVERRIDE.get(slug, coords(d))
    script = glob.glob(f"{d}/*_clean.txt"); assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    hero = [w for w in webps if w.endswith("_hero.webp")]; assert len(hero) == 1, d
    numbered = [w for w in webps if w not in hero]
    if slug in DROP_HERO:
        h = [w for w in numbered if num_of(w) == DROP_HERO[slug]]; assert len(h) == 1, (slug, h)
        numbered.remove(h[0]); hero = h
    rest = sorted((w for w in numbered if num_of(w) not in SKIP_IMAGES.get(slug, ())), key=num_of)
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
    assert len({s[2] for s in SPEC}) == len(SPEC) == 16
    assert len({s[0] for s in SPEC}) == 16
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
    have = {m["id"] for m in data["makers"]}
    for c in ("nap", "bri", "rom", "cag"):
        assert CODES.get(c, PREV_ID) in have, c
    at = next(i for i, m in enumerate(data["makers"]) if m["id"] == PREV_ID) + 1
    for code, name, emoji, bio in NEW_MAKERS:
        if CODES[code] in have:
            continue
        data["makers"].insert(at, {
            "id": CODES[code], "displayName": name, "platform": "dozent", "handle": f"atlas.{code}",
            "avatarURL": None, "avatarEmoji": emoji, "bio": bio, "websiteURL": None})
        at += 1
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; makers " + ", ".join(f"{c.upper()} {CODES[c]}" for c, *_ in NEW_MAKERS))


if __name__ == "__main__":
    main()
