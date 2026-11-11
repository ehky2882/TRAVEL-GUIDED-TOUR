#!/usr/bin/env python3
"""Build the Mexico City (MEX) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/athens-batch1/tools/wire_athens.py. Folders are matched by script number
(folder names arrived with #Uxxxx escapes for accented letters).

Usage: python3 -I wire_mexico_city.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-05"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Mexico City"

MEX_ID = str(uuid.uuid5(NS, "atlas-maker:mex"))

# script no., slug, title, category, tags, radius, caption
SPEC = [
 ("01", "alameda-central", "Alameda Central", "natureAndParks",
  ["Park", "History", "Power", "Public Art", "Green Escape", "Free to Visit"], 60,
  "On the park side of Avenida Juárez, facing the white marble crescent of the Hemiciclo a Juárez."),
 ("02", "arca-tierra", "Arca Tierra", "foodAndDrink",
  ["Venue", "Food", "Waterfront", "Green Escape", "Hidden Gem"], 50,
  "In Xochimilco, south of the Cuemanco landing, on the edge of a chinampa with the canal either side of you."),
 ("03", "biblioteca-vasconcelos", "Vasconcelos Library | Biblioteca Vasconcelos", "architecture",
  ["Library", "Architecture", "Art", "Literature", "Contemporary", "Free to Visit", DM, "Alberto Kalach"], 40,
  "Inside the long, tall hall of hanging bookshelves, beneath the graphite-drawn skeleton of a grey whale."),
 ("04", "bosque-de-chapultepec", "Chapultepec Park | Bosque de Chapultepec", "natureAndParks",
  ["Park", "History", "War", "Iconic Landmark", "Green Escape", "Free to Visit"], 60,
  "Beside the boating lake in the First Section, facing the wooded hill with Chapultepec Castle on its summit."),
 ("09", "circulo-mexicano", "Círculo Mexicano", "architecture",
  ["Notable Building", "Architecture", "Art", "Contemporary", "Viewpoint", DM, "Ambrosi Etchegaray"], 25,
  "On República de Guatemala behind the cathedral, outside number 20: a stone facade with tall shuttered windows."),
 ("05", "camino-real-polanco", "Camino Real Polanco", "architecture",
  ["Notable Building", "Architecture", "Art", "Modernist", "Public Art", DM, "Ricardo Legorreta"], 40,
  "On Mariano Escobedo, facing the pink and ochre walls and the churning round fountain in the forecourt."),
 ("06", "cantina-el-bosque", "Cantina El Bosque", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark"], 25,
  "On the corner of Calle Trece de Septiembre in San Miguel Chapultepec, by the low building with its terrace."),
 ("07", "carla-fernandez", "Carla Fernández", "culturalHeritage",
  ["Venue", "Fashion", "Commerce"], 25,
  "On Álvaro Obregón near Monterrey, looking across from the tree-lined central walkway at the shop windows."),
 ("08", "casa-bosques", "Casa Bosques", "literature",
  ["Venue", "Literature", "Food", "Commerce", "Hidden Gem"], 25,
  "At Córdoba 25 in Roma Norte, before the protected early-1900s house with white walls and books laid face-out."),
 ("10", "contramar", "Contramar", "foodAndDrink",
  ["Venue", "Food"], 25,
  "At Durango 200 in Roma Norte, looking through the wide-open front into the high-ceilinged dining room."),
 ("11", "el-califa-de-leon", "El Califa de León", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "On Ribera de San Cosme in San Rafael, at the narrow taco stand with a steel griddle and a queue outside."),
 ("12", "el-micky", "El Micky", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "On Avenida Jalisco in Tacubaya: white walls washed in purple neon, two storeys of music and a queue."),
 ("13", "el-turix", "El Turix", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "At Emilio Castelar 212 in Polanco, near Parque Lincoln: a tiny counter with people eating on the pavement."),
 ("14", "hotel-condesadf", "Hotel CondesaDF", "architecture",
  ["Notable Building", "Architecture", "Food", "Viewpoint", DM, "Javier Sánchez"], 30,
  "On the corner of Veracruz and Guadalajara, with Parque España behind you, facing the pale wedge-shaped building."),
 ("15", "issi", "Issi", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "On Mayorga, a short residential street in Lomas de Chapultepec, outside number 118."),
 ("16", "kurimanzutto", "Kurimanzutto", "visualArt",
  ["Venue", "Art", "Architecture", "Contemporary", "Free to Visit", DM, "Alberto Kalach"], 30,
  "At Gobernador Rafael Rebollar 94 in San Miguel Chapultepec, behind a plain wall: a long, low former lumber yard."),
 ("17", "lago", "LAGO", "architecture",
  ["Notable Building", "Architecture", "Engineering", "Art", "Food", "Modernist", "Waterfront", "Free to Visit",
   DM, "Alfonso Ramírez Ponce"], 40,
  "On the shore of the Lago Mayor in Chapultepec's Second Section, before the saddle-shaped concrete roof."),
 ("18", "lamartine-boutique-hotel", "Lamartine Boutique Hotel Polanco", "architecture",
  ["Notable Building", "Architecture", "Contemporary", "Hidden Gem", DM, "PPAA"], 25,
  "Across the road on Lamartine in Polanco, looking up at the fine metal mesh veiling the upper floors."),
 ("20", "mercado-jamaica", "Jamaica Market | Mercado de Jamaica", "culturalHeritage",
  ["Market", "Food", "Commerce", "Free to Visit"], 50,
  "Just inside the flower halls from Guillermo Prieto, near Jamaica metro, among buckets of roses and lilies."),
 ("21", "casa-estudio-diego-rivera-frida-kahlo",
  "Diego Rivera & Frida Kahlo House-Studio Museum | Museo Casa Estudio Diego Rivera y Frida Kahlo", "architecture",
  ["Museum", "Architecture", "Art", "Modernist", DM, "Juan O'Gorman"], 30,
  "At Altavista and Diego Rivera in San Ángel, facing the red and blue houses behind their organ-cactus fence."),
 ("22", "museo-jumex", "Museo Jumex", "visualArt",
  ["Museum", "Art", "Architecture", "Contemporary", DM, "David Chipperfield"], 40,
  "On the raised stone plaza, facing the pale building with its saw-tooth roof, the Museo Soumaya beside it."),
 ("23", "museo-nacional-de-antropologia",
  "National Museum of Anthropology | Museo Nacional de Antropología", "culturalHeritage",
  ["Museum", "History", "Architecture", "Modernist", "Iconic Landmark", DM, "Pedro Ramírez Vázquez",
   "Jorge Campuzano", "Rafael Mijares"], 50,
  "On the Paseo de la Reforma forecourt, before the seven-metre stone monolith of Tláloc."),
 ("24", "museo-tamayo", "Tamayo Museum | Museo Tamayo Arte Contemporáneo", "visualArt",
  ["Museum", "Art", "Architecture", "Brutalist", DM, "Teodoro González de León", "Abraham Zabludovsky"], 40,
  "At Paseo de la Reforma 51, among the trees on the park side, facing the low, stepped grey concrete building."),
 ("25", "unam", "National Autonomous University of Mexico | Universidad Nacional Autónoma de México", "architecture",
  ["Notable Building", "Architecture", "Art", "Modernist", "Public Art", "Iconic Landmark", "Free to Visit", DM,
   "Mario Pani", "Enrique del Moral", "Juan O'Gorman"], 60,
  "On the lawns of Ciudad Universitaria, facing the Central Library's stone mosaic, with the Rectoría to one side."),
 ("26", "octavia-casa", "Octavia Casa", "architecture",
  ["Notable Building", "Architecture", "Fashion", "Commerce", "Art Deco", "Hidden Gem", DM, "PPAA"], 25,
  "At Amatlán 126 in Hipódromo Condesa, before the narrow glass facade screened by slim timber louvres."),
 ("27", "onora", "Onora", "culturalHeritage",
  ["Venue", "Commerce", "Art"], 25,
  "At Lope de Vega 330 in Polanco, looking through the windows into a calm room of muted handmade pieces."),
 ("28", "plaza-garibaldi", "Garibaldi Square | Plaza Garibaldi", "musicAndPerformance",
  ["Public Square", "Performance", "History", "Iconic Landmark", "After Dark", "Free to Visit"], 50,
  "Off the Eje Central, in the open square among the mariachi bands in their silver-studded charro suits."),
 ("29", "quintonil", "Quintonil", "foodAndDrink",
  ["Venue", "Food"], 25,
  "At Newton 55 in Polanco, before a modest frontage that gives almost nothing away."),
 ("30", "san-angel-inn", "San Ángel Inn", "foodAndDrink",
  ["Venue", "Food", "History", "Colonial"], 30,
  "Across from the Rivera and Kahlo studios, facing the old hacienda's pale walls and arched gateway."),
 ("31", "sandra-weil", "Sandra Weil", "hiddenGems",
  ["Venue", "Fashion", "Commerce", "Architecture", "Hidden Gem", DM, "PPAA"], 25,
  "At Avenida Horacio 907, with Parque América behind you, facing a former house with a plant-filled balcony."),
 ("32", "ticuchi", "Ticuchi", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "At Petrarca 254 in Polanco, Pujol's old home: a near-blank front with a big window onto a working comal."),
 ("33", "tlecan", "Tlecan", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark"], 25,
  "At Álvaro Obregón 228 in Roma Norte, through the small doorway into a dim bar with a carved stone disc."),
 ("34", "xinu-perfumes", "Xinú Perfumes", "hiddenGems",
  ["Venue", "Commerce", "Hidden Gem"], 25,
  "At Alejandro Dumas 161 in Polanco: black walls and a black staircase rising to an upper floor."),
 ("36", "zocalo", "Zócalo", "history",
  ["Public Square", "History", "Power", "Colonial", "Iconic Landmark", "Free to Visit"], 80,
  "By the great flagpole, facing the cathedral's twin towers, with the National Palace along your right."),
 ("35", "zinco-jazz-club", "Zinco Jazz Club", "musicAndPerformance",
  ["Venue", "Performance", "After Dark", "Hidden Gem"], 25,
  "Outside Motolinía 20, at the corner of Cinco de Mayo: an old stone building with stairs leading down."),
]

# Four folder-name coordinates were not at the venue (triage, 2026-11-05):
COORD_OVERRIDE = {
    # was Calle Nápoles 45 (Colonia Juárez), ~4 km off; OSM restaurant node on the Lago Mayor shore
    "lago": (19.417232, -99.199780),
    # was Cerrada Monte Tauro, ~770 m north; Calle Mayorga is a ~100 m street (OSM way midpoint)
    "issi": (19.41066, -99.21776),
    # was ~700 m south of the Central Library; on the lawn just east of it, Rectoría to the south-west
    "unam": (19.33335, -99.18645),
    # was by the zoo enclosures ~380 m west; east shore of the First Section boating lake, castle to the east
    "bosque-de-chapultepec": (19.42280, -99.18440),
}

# The drop's lago-2 is byte-identical to bosque-de-chapultepec_2 (an aerial of Chapultepec's lakes that does not
# show LAGO's roof); it stays with the park and is skipped for LAGO.
SKIP_IMAGES = {"lago": {2}}


def folder(num):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and glob.glob(f"{d}/{num}_*_clean.txt")]
    assert len(m) == 1, (num, m)
    return m[0]


def coords(d):
    m = re.search(r"(-?\d+\.\d+),\s*(-?\d+\.\d+)\s*$", d)
    return (float(m.group(1)), float(m.group(2)))


def paras(path):
    txt = open(path, encoding="utf-8").read().replace("[beat]", "")
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
    num, slug, title, cat, tags, radius, caption = spec
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
    stem = f"mex-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"mex:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": MEX_ID,
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
        "country": "Mexico",
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }


def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    assert len({s[1] for s in SPEC}) == len(SPEC) == 35
    new = [build(s) for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == MEX_ID for m in data["makers"]):
        ath = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio ATH")
        data["makers"].insert(ath + 1, {
            "id": MEX_ID, "displayName": "Atlas Studio MEX", "platform": "dozent", "handle": "atlas.mex",
            "avatarURL": None, "avatarEmoji": "🇲🇽",
            "bio": "Atlas Studio's Mexico City bureau — the floating shelves of the Vasconcelos library, O'Gorman's "
                   "stone-mosaic campus, a concrete umbrella over the nation's oldest treasures, floating farms in "
                   "Xochimilco, a Michelin-starred taco stand, mariachis for hire and mezcal bars built like caves.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {MEX_ID}")


if __name__ == "__main__":
    main()
