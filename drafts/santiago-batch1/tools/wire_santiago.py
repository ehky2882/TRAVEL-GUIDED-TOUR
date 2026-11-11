#!/usr/bin/env python3
"""Build the Santiago (SCL) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/turin-batch1/tools/wire_turin.py."""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"  # unzipped drop
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"  # renamed media out
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-10-30"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"

SCL_ID = str(uuid.uuid5(NS, "atlas-maker:scl"))

# folder-prefix, script no., slug, title, category, tags, radius, caption, (lat, lon) override
SPEC = [
 ("Baco ", "01", "baco", "Baco", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 40,
  "At number 113 Nueva de Lyon in Providencia, by the patio tables and the wine shop next door.", None),
 ("Benedictine Monastery", "02", "benedictine-monastery-las-condes",
  "Benedictine Monastery of the Holy Trinity | Monasterio Benedictino de la Santísima Trinidad", "architecture",
  ["Religious Building", "Architecture", "Faith", "Modernist", "Viewpoint", "Free to Visit", DM,
   "Martín Correa", "Gabriel Guarda"], 50,
  "On the path up the hillside off Montecassino, just below the stepped white volumes of the church.", None),
 ("Borag#U00f3", "03", "borago", "Boragó", "foodAndDrink",
  ["Venue", "Food"], 40,
  "At number 5970 Avenida San José María Escrivá de Balaguer in Vitacura, with Cerro Manquehue to the north.",
  None),
 ("Cenco Costanera", "04", "gran-torre-costanera", "Gran Torre Costanera", "architecture",
  ["Tower", "Architecture", "Commerce", "Contemporary", "Viewpoint", "Iconic Landmark", DM, "César Pelli"], 50,
  "On the pavement of Avenida Andrés Bello, with the Mapocho and its park behind you and the tower ahead.", None),
 # the drop's point was ~90 m north; moved to OSM's point for Bandera 361
 ("Chilean Museum of Pre-Columbian Art", "05", "museo-chileno-de-arte-precolombino",
  "Chilean Museum of Pre-Columbian Art | Museo Chileno de Arte Precolombino", "culturalHeritage",
  ["Museum", "History", "Art", "Colonial", DM, "Smiljan Radić"], 40,
  "At the entrance on Bandera, number 361, at the corner of Compañía, a block west of the Plaza de Armas.",
  (-33.4390245, -70.6521952)),
 ("Drugstore Boulevard", "07", "drugstore", "Drugstore", "hiddenGems",
  ["Notable Building", "Commerce", "Fashion", "Literature", "Hidden Gem"], 40,
  "At the passage opening off Avenida Providencia at number 2124, near Los Leones metro station.", None),
 ("Fukasawa", "08", "fukasawa", "Fukasawa", "foodAndDrink",
  ["Venue", "Food", "Viewpoint", "After Dark"], 40,
  "At the CasaCostanera complex on Avenida Nueva Costanera; the restaurant is on the fourth-floor roof.", None),
 ("Hotel Bidasoa", "09", "hotel-bidasoa", "Hotel Bidasoa", "culturalHeritage",
  ["Venue", "Immigration", "Food", "Hidden Gem"], 40,
  "At number 4873 Avenida Vitacura, before the gardens, the original house and the newer tower alongside.", None),
 ("Hotel Magnolia", "10", "hotel-magnolia", "Hotel Magnolia", "architecture",
  ["Notable Building", "Architecture", "Food", "Art Deco", "Contemporary", DM,
   "Cazú Zegers", "Eduardo Costabal Zegers"], 40,
  "Outside number 539 Huérfanos, a block from the foot of Santa Lucía Hill, looking up at the glass floors.",
  None),
 ("LA CALMA", "11", "la-calma", "La Calma", "foodAndDrink",
  ["Venue", "Food", "Maritime"], 40,
  "Behind the terrace canopies at number 3832 Avenida Nueva Costanera, near the CasaCostanera complex.", None),
 ("La Cle Atelier", "06", "cristian-donoso-atelier", "Cristián Donoso Atelier & La Clé", "hiddenGems",
  ["Venue", "Art", "Food", "Hidden Gem"], 40,
  "At number 2860 Alonso de Córdova in Vitacura, by the showroom of handmade wooden furniture.", None),
 ("La Mesa", "12", "la-mesa", "La Mesa", "foodAndDrink",
  ["Venue", "Food"], 40,
  "At number 2767 Alonso de Córdova, at the entrance framed by olive trees and a kitchen garden.", None),
 # the drop's point was 260 m north on El Bosque Norte; moved to OSM's point for MUT (Apoquindo 2750)
 ("Mercado Urbano Tobalaba", "13", "mercado-urbano-tobalaba", "Mercado Urbano Tobalaba (MUT)", "architecture",
  ["Market", "Architecture", "Commerce", "Contemporary", "Green Escape", "Free to Visit"], 50,
  "Above Tobalaba metro station on Avenida Apoquindo, where Lines One and Four meet.",
  (-33.4172801, -70.6011321)),
 ("Mestizo -", "14", "mestizo", "Mestizo", "architecture",
  ["Venue", "Food", "Architecture", "Contemporary", DM, "Smiljan Radić"], 40,
  "On Avenida Bicentenario at the northern edge of Parque Bicentenario, before the row of granite boulders.",
  None),
 ("Mestizo Italia", "15", "mestizo-italia", "Mestizo Italia", "architecture",
  ["Venue", "Food", "Architecture", "Contemporary", "Hidden Gem", DM, "Smiljan Radić"], 40,
  "In Barrio Italia, between Avenida Italia, Marín and Santa Isabel, by the green column and the olive tree.",
  None),
 ("Patricia Ready", "16", "galeria-patricia-ready", "Patricia Ready Gallery | Galería Patricia Ready",
  "visualArt", ["Venue", "Art", "Architecture", "Contemporary", "Free to Visit", DM, "Izquierdo Lehmann"], 40,
  "At number 3125 Espoz in Vitacura, before the long, low building of bare concrete.", None),
 # the drop's point sat on Bandera behind the cathedral; moved into the south part of the square
 ("Plaza de Armas", "17", "plaza-de-armas", "Plaza de Armas", "history",
  ["Public Square", "History", "Power", "Colonial", "Iconic Landmark", "Free to Visit"], 60,
  "In the square, facing north towards the Central Post Office, with the cathedral on your left.",
  (-33.4379, -70.6505)),
 ("Santa Luc#U00eda Hill", "18", "cerro-santa-lucia", "Santa Lucía Hill | Cerro Santa Lucía", "natureAndParks",
  ["Park", "History", "Viewpoint", "Green Escape", "Free to Visit", "Iconic Landmark"], 50,
  "At the Neptune Terrace on the Alameda, the hill's grand entrance of twin staircases around a fountain.", None),
 ("Taller Roca Negra", "19", "taller-roca-negra", "Taller Roca Negra", "visualArt",
  ["Museum", "Art", "Public Art", "Viewpoint", "Hidden Gem"], 40,
  "On the road up the Maipo valley in San José de Maipo; a private home, so please look from the roadside.",
  None),
 ("The Singular Santiago", "20", "the-singular-santiago", "The Singular Santiago", "architecture",
  ["Venue", "Architecture", "Food", "Neoclassical", "Viewpoint"], 40,
  "Outside number 294 Merced in Lastarria, by the black façade and its understated signage.", None),
 ("Umbral Plazoleta Negra", "21", "umbral-plazoleta-negra",
  "Plazoleta Negra Threshold | Umbral Plazoleta Negra", "hiddenGems",
  ["Monument", "Faith", "Contemporary", "Public Art", "Viewpoint", "Free to Visit", DM, "Cazú Zegers"], 40,
  "At curve 22 on the road up to Farellones; pull in safely and keep well back from the edge.", None),
 ("Yum Cha", "22", "yum-cha", "Yum Cha", "foodAndDrink",
  ["Venue", "Food"], 40,
  "At number 2722 La Herradura, on a quiet stretch of Providencia.", None),
]

def folder(prefix):
    m = [d for d in glob.glob(f"{DROP}/output *") if os.path.basename(d)[7:].startswith(prefix)]
    assert len(m) == 1, (prefix, m)
    return m[0]

def coords(d):
    m = re.search(r"(-?\d+\.\d+),\s*(-?\d+\.\d+)\s*$", d)
    return (float(m.group(1)), float(m.group(2))) if m else None

def paras(path):
    txt = open(path, encoding="utf-8").read().replace("[beat]", "")
    ps = [re.sub(r"\s+", " ", p).strip() for p in re.split(r"\n\s*\n", txt)]
    ps = [p for p in ps if p]
    return ps[1:]  # drop the title line

def short(s, n=145):
    if len(s) <= n: return s
    return s[:n].rsplit(" ", 1)[0].rstrip(",;:") + "…"

def duration(mp3):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", mp3])
    return round(float(out))

def build(spec, code, file_prefix, maker_id, city):
    pre, num, slug, title, cat, tags, radius, caption, override = spec
    d = folder(pre)
    lat, lon = override or coords(d)
    script = glob.glob(f"{d}/{num}_*_clean.txt"); assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    # heroes arrive as "_hero.webp" or "-hero.webp" (the monastery); the rest end in a number
    hero = [w for w in webps if w.endswith("hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if w not in hero),
                  key=lambda w: int(re.search(r"(\d+)\.webp$", w).group(1)))
    stem = f"{file_prefix}-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"{code}:{file_prefix}-{slug}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": maker_id,
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
        "country": "Chile",
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }

def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    new = [build(s, "scl", "scl", SCL_ID, "Santiago") for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == SCL_ID for m in data["makers"]):
        trn = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio TRN")
        data["makers"].insert(trn + 1, {
            "id": SCL_ID, "displayName": "Atlas Studio SCL", "platform": "dozent", "handle": "atlas.scl",
            "avatarURL": None, "avatarEmoji": "🇨🇱",
            "bio": "Atlas Studio's Santiago bureau — a colonial square laid over an Inca settlement, a hill turned "
                   "pleasure garden, restaurants holding up their roofs on boulders and cooking from Chile's own "
                   "wild larder, the tallest tower in South America, and the Andes at the end of every street.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {SCL_ID}")

if __name__ == "__main__":
    main()
