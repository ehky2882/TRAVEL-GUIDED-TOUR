#!/usr/bin/env python3
"""Build the Nice (NCE) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/brasilia-batch1/tools/wire_brasilia.py. Folders are matched by script number.

Usage: python3 -I wire_nice.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-13"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Nice"
COUNTRY = "France"

NCE_ID = str(uuid.uuid5(NS, "atlas-maker:nce"))

# script no., slug, title, category, tags, radius, caption
SPEC = [
 ("01", "hotel-le-negresco", "Hôtel Le Negresco", "architecture",
  ["Notable Building", "Venue", "Waterfront", "Architecture", "History", "Art", "Iconic Landmark", DM, "Édouard-Jean Niermans"], 40,
  "On the sea side of the Promenade des Anglais, looking inland at the pink-domed white hotel."),
 ("02", "hotel-la-perouse", "Hôtel La Pérouse", "architecture",
  ["Venue", "Waterfront", "Viewpoint", "Architecture", "Hidden Gem"], 30,
  "On the Quai Rauba Capèu, at the hotel pressed into the foot of the Castle Hill."),
 ("03", "hotel-du-couvent", "Hôtel du Couvent", "architecture",
  ["Notable Building", "Venue", "History", "Faith", "Contemporary", "Green Escape", DM, "Studio Mumbai"], 40,
  "At the corner of Rue Honoré Ugo, before the long stone walls and shutters of the old convent."),
 ("04", "hotel-windsor", "Hôtel Windsor", "visualArt",
  ["Venue", "Art", "Contemporary", "Hidden Gem"], 25,
  "On Rue Dalpozzo, outside number eleven, a couple of blocks back from the Promenade."),
 ("05", "chez-pipo", "Chez Pipo", "foodAndDrink",
  ["Venue", "Food", "History"], 25,
  "On Rue Bavastro, up from the old port: the low frontage, the queue, and the oven glowing at the back."),
 ("06", "la-merenda", "La Merenda", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "On Rue Raoul Bosio, by the small dining room with the plain shopfront, near the Opéra."),
 ("07", "chez-acchiardo", "Chez Acchiardo", "foodAndDrink",
  ["Venue", "Food", "History", "Immigration"], 15,
  "Halfway along Rue Droite, at number thirty-eight, with the name Acchiardo over the door."),
 ("08", "peixes", "Peixes", "foodAndDrink",
  ["Venue", "Food", "Contemporary"], 25,
  "On Rue de l'Opéra, at the small bright dining room tiled in white and nautical blue."),
 ("09", "le-plongeoir", "Le Plongeoir", "foodAndDrink",
  ["Venue", "Food", "Waterfront", "Maritime", "Viewpoint", "Art Deco", DM, "René Livieri"], 40,
  "On the coast road east of the port, above the white diving-board tower on its rock in the sea."),
 ("10", "les-distilleries-ideales", "Les Distilleries Idéales", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 15,
  "On Rue de la Préfecture, at the corner terrace under the old-fashioned lettering."),
 ("11", "la-part-des-anges", "La Part des Anges", "foodAndDrink",
  ["Venue", "Food", "Commerce", "Hidden Gem"], 25,
  "On Rue Gubernatis, at number seventeen, the narrow shop with wine stacked to the ceiling."),
 ("12", "cafe-de-turin", "Café de Turin", "foodAndDrink",
  ["Venue", "Food", "Maritime", "History", "Iconic Landmark"], 20,
  "Under the arcades of Place Garibaldi, by the terrace and the counter piled with ice and shellfish."),
 ("13", "cafe-du-cycliste", "Café du Cycliste", "foodAndDrink",
  ["Venue", "Food", "Commerce", "Fashion", "Waterfront"], 25,
  "On the Quai des Docks, at number sixteen, bicycles leaning outside on the east side of the port."),
 ("14", "maison-auer", "Maison Auer", "foodAndDrink",
  ["Venue", "Food", "Commerce", "History"], 25,
  "On Rue Saint-François-de-Paule, opposite the opera house, at the window of shining fruit."),
 ("15", "moulin-a-huile-dolive-alziari", "Moulin à Huile d'Olive Alziari", "foodAndDrink",
  ["Venue", "Food", "Commerce", "History"], 25,
  "On Rue Saint-François-de-Paule, by the little shop with shelves of blue and yellow tins."),
 ("16", "confiserie-florian", "Confiserie Florian", "foodAndDrink",
  ["Venue", "Food", "Commerce", "Maritime"], 25,
  "On the Quai Papacino, west side of the old port, at the window full of glazed fruit."),
 ("17", "mamac", "MAMAC – Museum of Modern and Contemporary Art | Musée d'Art Moderne et d'Art Contemporain", "visualArt",
  ["Museum", "Art", "Architecture", "Contemporary", DM, "Yves Bayard", "Henri Vidal"], 50,
  "On Place Yves Klein, facing the four white marble towers joined by glass bridges."),
 ("18", "musee-marc-chagall", "Musée National Marc Chagall", "visualArt",
  ["Museum", "Art", "Faith", "Modernist", "Green Escape", DM, "André Hermant"], 40,
  "On Avenue du Docteur Ménard, at the entrance to the low white building in its blue and white garden."),
 ("19", "musee-matisse", "Musée Matisse", "visualArt",
  ["Museum", "Art", "History", "Green Escape", DM, "Jean-François Bodin"], 50,
  "In the olive grove of the Cimiez Arènes park, facing the big red villa and its painted windows."),
 ("20", "musee-des-arts-asiatiques", "Museum of Asian Arts | Musée des Arts Asiatiques", "architecture",
  ["Museum", "Art", "Architecture", "Contemporary", "Green Escape", DM, "Kenzō Tange"], 50,
  "On the edge of the lake in Parc Phoenix, before the white marble cubes floating on the water."),
 ("21", "villa-arson", "Villa Arson", "architecture",
  ["Notable Building", "Art", "Architecture", "Brutalist", "Green Escape", "Hidden Gem", DM, "Michel Marot"], 60,
  "At the gates on Avenue Stephen Liégeard, the old villa and the stepped concrete school beyond."),
 ("22", "eglise-sainte-jeanne-darc", "Church of Saint Joan of Arc | Église Sainte-Jeanne-d'Arc", "sacredSites",
  ["Religious Building", "Faith", "Architecture", "Art Deco", "Engineering", "Hidden Gem", DM, "Jacques Droz"], 40,
  "On Avenue Saint-Lambert, before the white egg-shaped domes and the tall, thin bell tower."),
 ("23", "cathedrale-saint-nicolas", "Saint Nicholas Russian Orthodox Cathedral | Cathédrale Orthodoxe Russe Saint-Nicolas", "sacredSites",
  ["Religious Building", "Faith", "History", "Immigration", "Iconic Landmark", DM, "Mikhail Preobrazhensky"], 40,
  "On Avenue Nicolas II, west of the station, facing the five onion domes."),
 ("24", "palais-lascaris", "Palais Lascaris", "culturalHeritage",
  ["Museum", "Notable Building", "History", "Baroque"], 25,
  "On Rue Droite, at the tall facade with the carved doorway and stone balconies."),
 ("25", "colline-du-chateau", "Castle Hill | Colline du Château", "natureAndParks",
  ["Park", "Viewpoint", "History", "Green Escape", "Free to Visit", "Iconic Landmark"], 60,
  "On the upper terraces of the hill, at the viewpoint looking west over the old town and the bay."),
 ("26", "monument-aux-morts-rauba-capeu", "Rauba-Capèu War Memorial | Monument aux Morts de Rauba-Capèu", "history",
  ["Monument", "Remembrance", "War", "Waterfront", "Art Deco", "Free to Visit", DM, "Roger Séassal"], 40,
  "On the Quai Rauba Capèu, before the tall arched niche and stone urn set into the cliff."),
 ("27", "promenade-du-paillon", "Promenade du Paillon", "natureAndParks",
  ["Park", "Green Escape", "History", "Contemporary", "Free to Visit", DM, "Michel Péna"], 60,
  "By the big shallow water mirror in the park, its fountains rising out of the paving."),
 ("28", "cours-saleya", "Cours Saleya", "culturalHeritage",
  ["Market", "Public Square", "Food", "Art", "History", "Free to Visit", "Iconic Landmark"], 50,
  "In the market square, at the eastern end, facing the tall yellow building where Matisse lived."),
 ("29", "tete-carree", "Square Head | Tête Carrée", "visualArt",
  ["Public Art", "Art", "Library", "Contemporary", "Free to Visit", DM, "Yves Bayard", "Francis Chapus"], 40,
  "Behind the MAMAC, by the Louis Nucéra library, looking up at the giant faceless cube of a head."),
 ("30", "place-garibaldi", "Place Garibaldi", "history",
  ["Public Square", "History", "Architecture", "Neoclassical", "Free to Visit", DM, "Antoine Spinelli"], 25,
  "In the arcaded ochre square, by Garibaldi's statue in its little garden."),
 ("31", "musee-massena", "Musée Masséna", "culturalHeritage",
  ["Museum", "History", "Art", "Waterfront", "Green Escape", DM, "Hans-Georg Tersling"], 40,
  "On the Promenade des Anglais, at the garden gates of the white Belle Époque villa."),
 ("32", "les-delices-de-candice", "Les Délices de Candice", "hiddenGems",
  ["Venue", "Commerce", "Fashion", "Art", "Hidden Gem"], 20,
  "On Rue de la Préfecture, at number seventeen, the small window full of rings and necklaces."),
]

# Owner-approved (2026-11-13): the supplied point was ~72 m north of the shop; 17 Rue de la Préfecture
# per the script, acceslibre and OSM's address point.
COORD_OVERRIDE = {
    "les-delices-de-candice": (43.696614, 7.27507),
}
SKIP_IMAGES = {}
TEXT_FIX = {}


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
    stem = f"nce-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"nce:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": NCE_ID,
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
    assert len({s[1] for s in SPEC}) == len(SPEC) == 32
    assert len({s[0] for s in SPEC}) == 32
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
    if not any(m["id"] == NCE_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio BSB")
        data["makers"].insert(prev + 1, {
            "id": NCE_ID, "displayName": "Atlas Studio NCE", "platform": "dozent", "handle": "atlas.nce",
            "avatarURL": None, "avatarEmoji": "🇫🇷",
            "bio": "Atlas Studio's Nice bureau — a city that was Italian until 1860 and still eats like it: socca "
                   "from a wood-fired oven, a family kitchen on Rue Droite since 1927, candied fruit opposite the "
                   "opera; the Belle Époque palaces of the Promenade des Anglais, a Russian cathedral built for a "
                   "tsarevich, and the museums Matisse, Chagall and Kenzō Tange left on the hills above the bay.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {NCE_ID}")


if __name__ == "__main__":
    main()
