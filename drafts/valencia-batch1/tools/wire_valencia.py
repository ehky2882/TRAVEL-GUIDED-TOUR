#!/usr/bin/env python3
"""Build the Valencia (VLC) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/santiago-batch1/tools/wire_santiago.py.

Usage: python3 -I wire_valencia.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-01"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"

VLC_ID = str(uuid.uuid5(NS, "atlas-maker:vlc"))

# folder-prefix (after the first word), script no., slug, title, category, tags, radius, caption, city, override
SPEC = [
 ("Bombas Gens", "01", "bombas-gens", "Bombas Gens Centre d'Arts Digitals", "architecture",
  ["Museum", "Architecture", "Art", "Engineering", "Art Deco", "Hidden Gem", DM,
   "Cayetano Borso di Carminati", "Annabelle Selldorf"], 50,
  "On the pavement opposite the brick frontage on Avinguda de Burjassot, in Marxalenes.", "Valencia", None),
 ("Cabecera Park", "02", "cabecera-park", "Cabecera Park | Parc de Capçalera", "natureAndParks",
  ["Park", "Architecture", "Green Escape", "Viewpoint", "Free to Visit", "Contemporary", DM,
   "Eduardo de Miguel", "Arancha Muñoz", "Vicente Corell"], 80,
  "At the edge of the lake, facing the wooded islands, with the viewpoint hill rising beyond the trees.",
  "Valencia", None),
 ("Cafe de las Horas", "03", "cafe-de-las-horas", "Café de las Horas", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Hidden Gem"], 40,
  "At number 1 Carrer del Comte d'Almodóvar, the narrow lane just off the Plaza de la Virgen.", "Valencia", None),
 ("Caro Hotel", "04", "caro-hotel", "Caro Hotel", "culturalHeritage",
  ["Notable Building", "History", "Architecture", "Hidden Gem"], 40,
  "Outside number 14 on the quiet Calle del Almirante, a few minutes east of the cathedral.", "Valencia", None),
 ("Central Market", "05", "central-market", "Central Market | Mercat Central", "architecture",
  ["Market", "Architecture", "Food", "Commerce", "Iconic Landmark", "Free to Visit", DM,
   "Alejandro Soler March", "Francisco Guardia Vial"], 50,
  "In the square with your back to the Silk Exchange, facing the market's long tiled frontage.", "Valencia", None),
 ("Centro de Arte Hortensia Herrero", "06", "cahh",
  "Hortensia Herrero Art Centre (CAHH) | Centre d'Art Hortensia Herrero", "visualArt",
  ["Museum", "Art", "History", "Baroque", "Contemporary"], 40,
  "Before the restored front of the Palau de Valeriola, number 31 Calle del Mar, east of the Plaza de la Reina.",
  "Valencia", None),
 ("Cervecer#U00eda Aquarium", "07", "cerveceria-aquarium", "Cervecería Aquarium", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Hidden Gem"], 40,
  "At number 57 Gran Vía del Marqués del Turia, the tree-lined avenue with a promenade down its centre.",
  "Valencia", None),
 ("CHAPEAU VALENCIA", "08", "chapeau-valencia", "Chapeau Valencia", "architecture",
  ["Notable Building", "Fashion", "Commerce", "Architecture", "Contemporary", DM, "Ramón Esteve"], 40,
  "Under the black steel canopy at number 5 Carrer d'Hernán Cortés, near the Mercado de Colón.", "Valencia", None),
 ("El Umbracle", "09", "el-umbracle", "El Umbracle | L'Umbracle", "architecture",
  ["Park", "Architecture", "Contemporary", "Public Art", "Free to Visit", "Green Escape", DM,
   "Santiago Calatrava"], 60,
  "On the raised promenade inside the Umbracle, looking along the white arches of the City of Arts and Sciences.",
  "Valencia", None),
 ("Espai Alfaro", "10", "espai-alfaro", "Espai Alfaro", "visualArt",
  ["Museum", "Art", "Public Art", "Hidden Gem", DM, "Emilio Giménez"], 50,
  "On Avinguda Andreu Alfaro in Godella's industrial estate; visits are usually arranged in advance.",
  "Godella", None),
 # the contributor supplied the farmhouse's own point at triage (the folder's sat ~15 m off)
 ("Genu#U00ed Cosmopolita", "11", "genui-cosmopolita", "Genuí Cosmopolita", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 60,
  "At the restored farmhouse inside the Club de Golf Escorpión, near Bétera; open to non-members.",
  "Bétera", (39.57743843741576, -0.47309236114223435)),
 ("Gr#U00e0ffica Showroom", "12", "graffica-showroom", "Gràffica Showroom", "hiddenGems",
  ["Venue", "Art", "Literature", "Commerce", "Hidden Gem"], 40,
  "At number 16 Calle del Almudín, behind the cathedral, beside the brick flank of the medieval grain store.",
  "Valencia", None),
 ("GRAN MART#U00cdNEZ", "13", "gran-martinez", "Gran Martínez", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark", "Hidden Gem"], 40,
  "At number 318 Avenida del Puerto, near where the long road from the city reaches the port.", "Valencia", None),
 ("HABITUAL", "14", "habitual", "Habitual by Ricard Camarena", "foodAndDrink",
  ["Venue", "Food", "Market", "Architecture", DM, "Francisco Mora Berenguer"], 40,
  "Before the Art Nouveau front of the Mercado de Colón on Calle de Jorge Juan; the restaurant is downstairs.",
  "Valencia", None),
 ("HIFI VALENCIA", "15", "hifi-valencia", "HiFi Valencia", "musicAndPerformance",
  ["Venue", "Performance", "After Dark", "Hidden Gem"], 40,
  "At number 91 Calle de Jesús, a street with a long pedigree for late nights.", "Valencia", None),
 ("Hotel Hospes", "16", "hospes-palau-de-la-mar", "Hospes Palau de la Mar", "architecture",
  ["Notable Building", "Architecture", "History"], 40,
  "Before the twin facades at number 14 Calle Navarro Reverter, a minute from the Porta de la Mar.",
  "Valencia", None),
 # the folder's point sat in the riverbed ~320 m from the bridge; moved onto the Pont de la Trinitat (OSM)
 ("Jard#U00edn del Turia", "17", "jardin-del-turia", "Turia Gardens | Jardí del Túria", "natureAndParks",
  ["Park", "Bridge", "History", "Green Escape", "Free to Visit", "Iconic Landmark", "Gothic", DM,
   "Ricardo Bofill"], 50,
  "In the middle of the Pont de la Trinitat, looking down over the parapet into the old riverbed.",
  "Valencia", (39.479023, -0.372695)),
 ("La Lonja de la Seda", "18", "lonja-de-la-seda", "Silk Exchange | Llotja de la Seda", "architecture",
  ["Notable Building", "Architecture", "Commerce", "History", "Gothic", "Iconic Landmark", DM, "Pere Compte"], 50,
  "In the square with the Central Market at your back, facing the long Gothic front and its square tower.",
  "Valencia", None),
 ("LAVOE", "19", "lavoe-arroz-y-mar", "Lavoe Arroz y Mar", "foodAndDrink",
  ["Venue", "Food"], 40,
  "On Carrer de la Creu Nova, a narrow old-town street a few minutes from the Plaza de la Reina.", "Valencia", None),
 ("Llibreries Par#U00eds", "20", "llibreries-paris-valencia", "Llibreries París València", "literature",
  ["Venue", "Literature", "Commerce", "Hidden Gem"], 40,
  "At number 7 Calle de Pelayo, just along the street from the Estación del Norte.", "Valencia", None),
 ("Llisa Negra", "21", "llisa-negra", "Llisa Negra", "foodAndDrink",
  ["Venue", "Food"], 40,
  "At the corner of Carrer de Pascual i Genís and Carrer de Correus, near the Plaza del Ayuntamiento.",
  "Valencia", None),
 # the folder's point sat ~100 m north of the palace; moved onto the building (OSM), whose door faces Poeta Querol
 ("Palace of the Marqu", "22", "palace-marques-de-dos-aguas",
  "Palace of the Marqués de Dos Aguas | Palau del Marqués de Dosaigües", "architecture",
  ["Museum", "Architecture", "Art", "Baroque", "Iconic Landmark", DM, "Hipólito Rovira"], 40,
  "On Calle del Poeta Querol, before the alabaster doorway and its two water-pouring figures.",
  "Valencia", (39.4725, -0.3748026)),
 ("Palacio Santa Clara", "23", "palacio-santa-clara", "Palacio Santa Clara", "architecture",
  ["Notable Building", "Architecture", "Commerce", "Viewpoint", DM, "Francisco Javier Goerlich"], 40,
  "Before the modernist town house on Carrer de Santa Clara, close to the Plaza del Ayuntamiento.",
  "Valencia", None),
 ("Parc Central", "24", "parc-central", "Parc Central", "natureAndParks",
  ["Park", "History", "Green Escape", "Free to Visit", "Contemporary", DM, "Kathryn Gustafson"], 60,
  "In the Plaza de Demetrio Ribes at the centre of the park, among the old railway warehouses.", "Valencia", None),
 ("Parque Natural de la Albufera", "25", "albufera-natural-park",
  "Albufera Natural Park | Parc Natural de l'Albufera", "natureAndParks",
  ["Park", "Waterfront", "Food", "Green Escape", "Viewpoint", "Free to Visit"], 120,
  "At the lagoon's edge by the Gola de Pujol viewpoint, south of the city on the road to El Palmar.",
  "Valencia", None),
 ("Pasaje 94", "26", "pasaje-94", "Pasaje 94", "hiddenGems",
  ["Venue", "Food", "Architecture", "Hidden Gem"], 40,
  "At number 13 Carrer dels Trinitaris, in the northern part of the old town; closed Sundays and Mondays.",
  "Valencia", None),
 ("Restaurante H#U014dch#U014d", "27", "restaurante-hocho", "Restaurante Hōchō", "foodAndDrink",
  ["Venue", "Food"], 40,
  "Inside the SH Valencia Palace hotel on Paseo de la Alameda, near the Palau de la Música.", "Valencia", None),
 ("Valencia Cathedral", "28", "valencia-cathedral", "Valencia Cathedral | Catedral de València", "sacredSites",
  ["Religious Building", "Faith", "History", "Gothic", "Iconic Landmark", "Viewpoint"], 60,
  "In the Plaza de la Virgen, facing the Gothic Door of the Apostles, with the Miguelete above the rooftops.",
  "Valencia", None),
 ("Veles e Vents", "29", "veles-e-vents", "Veles e Vents", "architecture",
  ["Notable Building", "Architecture", "Maritime", "Waterfront", "Contemporary", "Viewpoint", DM,
   "David Chipperfield", "Fermín Vázquez"], 50,
  "Before the stacked white decks on the edge of the marina, at the port end of the city.", "Valencia", None),
 ("VIVOOD", "30", "vivood-landscape-hotel", "VIVOOD Landscape Hotel", "architecture",
  ["Notable Building", "Architecture", "Contemporary", "Viewpoint", "Green Escape", DM,
   "Daniel Mayo", "Agustín Marí", "Pablo Vázquez"], 80,
  "On the terraced hillside near Benimantell, in the Guadalest valley of Alicante province.",
  "Benimantell", None),
]

def folder(prefix):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d)
         and os.path.basename(d).split(" ", 1)[1].startswith(prefix)]
    assert len(m) == 1, (prefix, m)
    return m[0]

def coords(d):
    m = re.search(r"(-?\d+\.\d+),\s*(-?\d+\.\d+)\s*$", d)
    return (float(m.group(1)), float(m.group(2)))

def paras(path):
    txt = open(path, encoding="utf-8").read().replace("[beat]", "")
    ps = [re.sub(r"\s+", " ", p).strip() for p in re.split(r"\n\s*\n", txt)]
    return [p for p in ps if p][1:]  # drop the title line

def short(s, n=145):
    if len(s) <= n: return s
    return s[:n].rsplit(" ", 1)[0].rstrip(",;:") + "…"

def duration(mp3):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", mp3])
    return round(float(out))

def build(spec):
    pre, num, slug, title, cat, tags, radius, caption, city, override = spec
    d = folder(pre)
    lat, lon = override or coords(d)
    script = glob.glob(f"{d}/{num}_*_clean.txt"); assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    hero = [w for w in webps if w.endswith("hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if w not in hero),
                  key=lambda w: int(re.search(r"(\d+)\.webp$", w).group(1)))
    stem = f"vlc-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"vlc:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": VLC_ID,
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
        "country": "Spain",
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }

def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    new = [build(s) for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == VLC_ID for m in data["makers"]):
        scl = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio SCL")
        data["makers"].insert(scl + 1, {
            "id": VLC_ID, "displayName": "Atlas Studio VLC", "platform": "dozent", "handle": "atlas.vlc",
            "avatarURL": None, "avatarEmoji": "🇪🇸",
            "bio": "Atlas Studio's Valencia bureau — a river turned into a nine-kilometre garden after the flood of "
                   "1957, a Gothic silk exchange that put business ethics on the wall in gold, farmers settling "
                   "water disputes at the cathedral door every Thursday, Calatrava's white ribs by the sea, and the "
                   "lagoon where paella began.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {VLC_ID}")

if __name__ == "__main__":
    main()
