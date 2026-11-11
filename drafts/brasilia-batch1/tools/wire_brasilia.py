#!/usr/bin/env python3
"""Build the Brasília (BSB) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/kuala-lumpur-batch1/tools/wire_kuala_lumpur.py. Folders are matched by script number
(folder names arrive with #Uxxxx escapes for non-ASCII letters, e.g. Bras#U00edlia).

Usage: python3 -I wire_brasilia.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-11"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
ON = "Oscar Niemeyer"
LC = "Lúcio Costa"
BM = "Roberto Burle Marx"
LELE = "João Filgueiras Lima"
CITY = "Brasília"
COUNTRY = "Brazil"

BSB_ID = str(uuid.uuid5(NS, "atlas-maker:bsb"))

# script no., slug, title, category, tags, radius, caption
SPEC = [
 ("01", "brasilia-palace-hotel", "Brasília Palace Hotel", "architecture",
  ["Notable Building", "Venue", "Architecture", "History", "Modernist", DM, ON], 40,
  "On the forecourt by the main entrance, road behind you, facing the long low block lifted on slim columns."),
 ("02", "royal-tulip-brasilia-alvorada", "Royal Tulip Brasília Alvorada", "architecture",
  ["Notable Building", "Venue", "Waterfront", "Architecture", "Contemporary", "Public Art", DM, "Ruy Ohtake"], 40,
  "At the entrance, access road behind you, facing the great curve of rooms that wraps round to the lake."),
 ("04", "mangai", "Mangai", "foodAndDrink",
  ["Food", "Waterfront", "Immigration"], 30,
  "At the lake-side entrance in the Sports Clubs Sector South, the JK Bridge arches down the shore."),
 ("05", "daniel-briand", "Daniel Briand Pâtissier & Chocolatier", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "On the shopping strip of Quadra 104 North, Block A: pavement tables, checked cloths through the window."),
 ("06", "mane-mercado", "Mané Mercado", "foodAndDrink",
  ["Market", "Food", "Contemporary", "BLOCO Arquitetos"], 50,
  "At the main entrance on the Monumental Axis side, the Mané Garrincha stadium off to one side."),
 ("07", "beirute", "Beirute", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem", "After Dark"], 25,
  "On the corner of the 109 South shopping strip, tables spilling out under the trees. The original Beirute."),
 ("08", "ernesto-cafes-especiais", "Ernesto Cafés Especiais", "foodAndDrink",
  ["Venue", "Food"], 25,
  "On the shopping strip of Quadra 115 South, in front of Block C, at the far south of the Asa Sul."),
 ("09", "clube-do-choro", "Choro Club | Clube do Choro de Brasília", "musicAndPerformance",
  ["Venue", "Performance", "After Dark", DM, ON], 40,
  "In front of the low curved white building just west of the TV Tower, wrapped round its courtyard."),
 ("10", "casa-de-cha", "Tea House | Casa de Chá", "foodAndDrink",
  ["Venue", "Food", "Architecture", "Modernist", "Hidden Gem", DM, ON], 20,
  "On the Square of the Three Powers: look down for the low pavilion sunk half into the paving."),
 ("11", "feira-da-torre-de-tv", "TV Tower Market | Feira da Torre de TV", "culturalHeritage",
  ["Market", "Commerce", "Art", "Free to Visit"], 50,
  "Among the craft pavilions at the foot of the TV Tower, on the Monumental Axis."),
 ("12", "fundacao-athos-bulcao", "Athos Bulcão Foundation | Fundação Athos Bulcão", "visualArt",
  ["Venue", "Art", "Commerce", "Hidden Gem"], 20,
  "On the W3 South at Quadra 510, Block B: the shop with his blue and white patterns in the window."),
 ("13", "catedral-metropolitana", "Metropolitan Cathedral | Catedral Metropolitana Nossa Senhora Aparecida",
  "sacredSites",
  ["Religious Building", "Faith", "Modernist", "Iconic Landmark", "Free to Visit", DM, ON], 50,
  "On the plaza in front of the cathedral, facing the ramp down to the entrance and its ring of ribs."),
 ("14", "palacio-itamaraty", "Itamaraty Palace | Palácio Itamaraty", "architecture",
  ["Civic", "Power", "Modernist", "Iconic Landmark", DM, ON, BM], 60,
  "On the Esplanada pavement opposite the Foreign Ministry, across its water garden and arches."),
 ("15", "congresso-nacional", "National Congress | Congresso Nacional", "architecture",
  ["Civic", "Power", "Modernist", "Iconic Landmark", DM, ON], 60,
  "At the Congress platform, the bowl and the dome either side of the two towers."),
 ("16", "santuario-dom-bosco", "Dom Bosco Sanctuary | Santuário Dom Bosco", "sacredSites",
  ["Religious Building", "Faith", "Art", "Modernist", "Iconic Landmark", "Free to Visit", "Carlos Alberto Naves"], 40,
  "On the W3 South at Quadra 702, before the square building framed by tall pointed concrete arches."),
 ("17", "igrejinha", "Little Church of Our Lady of Fátima | Igrejinha Nossa Senhora de Fátima", "sacredSites",
  ["Religious Building", "Faith", "Public Art", "Modernist", "Free to Visit", DM, ON], 30,
  "On the grass beside the little church at 307 South, facing its open front and tilted roof."),
 ("18", "memorial-jk", "JK Memorial | Memorial JK", "history",
  ["Monument", "Museum", "Remembrance", "Power", "Modernist", DM, ON], 50,
  "At the foot of the memorial at the west end of the Monumental Axis, looking up at JK on his pillar."),
 ("19", "museu-nacional", "National Museum | Museu Nacional Honestino Guimarães", "architecture",
  ["Museum", "Remembrance", "Modernist", DM, ON], 50,
  "On the paving of the Cultural Complex of the Republic, facing the white dome and its long ramp."),
 ("20", "teatro-nacional", "National Theatre | Teatro Nacional Cláudio Santoro", "musicAndPerformance",
  ["Venue", "Performance", "Public Art", "Modernist", DM, ON], 60,
  "Beside the theatre in the Cultural Sector North, facing a sloping side covered in Athos's blocks."),
 ("21", "instituto-central-de-ciencias", "Central Institute of Sciences | Instituto Central de Ciências",
  "architecture",
  ["Notable Building", "Engineering", "Brutalist", "Green Escape", DM, ON, LELE], 80,
  "In the central garden of the Minhocão at the University of Brasília, looking along its two long wings."),
 ("22", "hospital-sarah-lago-norte", "Hospital SARAH Lago Norte", "architecture",
  ["Notable Building", "Engineering", "Waterfront", "Contemporary", DM, LELE], 80,
  "Outside the working hospital by the lake, looking at the waves of its roofs. Please don't go in."),
 ("23", "ccbb-brasilia", "Banco do Brasil Cultural Centre | Centro Cultural Banco do Brasil", "visualArt",
  ["Venue", "Art", "Waterfront", "Green Escape", "Free to Visit", DM, ON], 60,
  "In the lake-side gardens, the long bare concrete building behind you and the JK Bridge across the water."),
 ("24", "catetinho", "Catetinho", "history",
  ["Notable Building", "History", "Power", "Green Escape", "Free to Visit", "Hidden Gem", ON], 40,
  "In the clearing in front of the long timber house on stilts, in Cerrado woodland south of the city."),
 ("25", "sqs-308", "Superquadra 308 South | SQS 308 Sul", "architecture",
  ["District", "Architecture", "Modernist", "Green Escape", DM, BM, "Sérgio Rocha", "Marcelo Campelo"], 80,
  "In the garden at the heart of 308 South, between the six-storey blocks raised on columns."),
 ("26", "torre-de-tv", "TV Tower | Torre de TV", "architecture",
  ["Tower", "Viewpoint", "Engineering", "Iconic Landmark", "Modernist", DM, LC], 50,
  "On the Monumental Axis between the tower's three concrete legs, the craft market all round you."),
 ("27", "rodoviaria", "Central Bus Station | Rodoviária do Plano Piloto", "architecture",
  ["Civic", "Architecture", "Modernist", DM, LC], 60,
  "On the bus platform of the Rodoviária, one avenue over your head and another under your feet."),
 ("28", "conic", "Conic", "hiddenGems",
  ["District", "Commerce", "Performance", "Modernist", "After Dark", "Hidden Gem"], 50,
  "In the passages of the Conic beside the bus station, signs stacked on signs. Mind your belongings."),
 ("29", "ermida-dom-bosco", "Dom Bosco Hermitage | Ermida Dom Bosco", "sacredSites",
  ["Religious Building", "Faith", "Viewpoint", "Green Escape", "Free to Visit", ON], 40,
  "On the slope beside the little white pyramid chapel, the lake and the whole city across the water."),
 ("30", "ponte-jk", "JK Bridge | Ponte JK", "architecture",
  ["Bridge", "Engineering", "Contemporary", "Iconic Landmark", "After Dark", DM, "Alexandre Chan"], 80,
  "On the bridge walkway, the three leaning steel arches skipping across the lake."),
 ("31", "pontao-do-lago-sul", "Pontão do Lago Sul", "natureAndParks",
  ["Waterfront", "Food", "Green Escape", "After Dark", "Free to Visit"], 60,
  "On the lakeside promenade in the middle of the Pontão, the restaurants behind you."),
 ("32", "espaco-lucio-costa", "Lúcio Costa Space | Espaço Lúcio Costa", "history",
  ["Museum", "Architecture", "History", "Hidden Gem", DM, ON], 20,
  "On the Square of the Three Powers: find the low entrance in the paving and go down the steps."),
]

# Owner-approved moves onto the subject (2026-11-11), from the venue's own OpenStreetMap object.
# Congress and the JK Bridge were also proposed, but were already on their subject (inside the Congress
# polygon; on the bridge deck 8 m from its centre line) — the 150 m was measured to a fountain and to the
# bridge's mid-point. They are left as supplied.
COORD_OVERRIDE = {
    "hospital-sarah-lago-norte": (-15.7527096, -47.8293205),  # OSM hospital, was 146 m west
    "teatro-nacional": (-15.791896, -47.8803283),              # OSM theatre, was 103 m west
    "conic": (-15.795721, -47.8846815),                        # OSM mall polygon, was 99 m north-east
}
SKIP_IMAGES = {}
TEXT_FIX = {"Brasílians": "Brasilians"}


def folder(num):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and glob.glob(f"{d}/{num}_*_clean.txt")]
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
    num, slug, title, cat, tags, radius, caption = spec[:7]
    d = folder(num)
    lat, lon = COORD_OVERRIDE.get(slug, coords(d))
    script = glob.glob(f"{d}/{num}_*_clean.txt"); assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    hero = [w for w in webps if w.endswith("_hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if w not in hero
                   and int(re.search(r"_(\d+)\.webp$", w).group(1)) not in SKIP_IMAGES.get(slug, ())),
                  key=lambda w: int(re.search(r"_(\d+)\.webp$", w).group(1)))
    stem = f"bsb-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"bsb:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": BSB_ID,
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
        "city": CITY,
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
    assert len({s[1] for s in SPEC}) == len(SPEC) == 31
    assert len({s[0] for s in SPEC}) == 31
    for s in SPEC:
        assert len(s[6]) <= 110, (s[1], len(s[6]))
    new = [build(s) for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    for i, a in enumerate(new):
        for b in new[i + 1:]:
            sa, sb = a["stops"][0], b["stops"][0]
            dd = dist((sa["latitude"], sa["longitude"]), (sb["latitude"], sb["longitude"]))
            if dd < sa["triggerRadiusMeters"] + sb["triggerRadiusMeters"]:
                print(f"OVERLAP {a['title']} / {b['title']}: {dd:.0f} m", file=sys.stderr)
    if not any(m["id"] == BSB_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio WAS")
        data["makers"].insert(prev + 1, {
            "id": BSB_ID, "displayName": "Atlas Studio BSB", "platform": "dozent", "handle": "atlas.bsb",
            "avatarURL": None, "avatarEmoji": "🇧🇷",
            "bio": "Atlas Studio's Brasília bureau — a capital drawn as a cross on a sheet of paper and built on "
                   "empty scrubland in four years: Niemeyer's palaces and a cathedral you enter from below, the "
                   "superquadras where the plan actually lives, the wooden house where it all began, and the "
                   "bars, markets and lakeside promenades that nobody planned at all.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {BSB_ID}")


if __name__ == "__main__":
    main()
