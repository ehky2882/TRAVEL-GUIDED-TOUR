#!/usr/bin/env python3
"""Build the Lyon (LYS) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/nice-batch1/tools/wire_lyon.py. Folders are matched by script number.

Usage: python3 -I wire_lyon.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-14"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Lyon"
COUNTRY = "France"

LYS_ID = str(uuid.uuid5(NS, "atlas-maker:lys"))

# script no., slug, title, category, tags, radius, caption[, city]
SPEC = [
 ("01", "les-halles-de-lyon-paul-bocuse", "Les Halles de Lyon Paul Bocuse", "foodAndDrink",
  ["Market", "Food", "Commerce", "Iconic Landmark"], 50,
  "On Cours Lafayette at Rue Garibaldi, before the long, low block of glass and concrete."),
 ("02", "daniel-et-denise-saint-jean", "Daniel et Denise Saint-Jean", "foodAndDrink",
  ["Venue", "Food", "History"], 20,
  "On Rue Tramassac in Saint-Jean, at the small bouchon with the name over the door."),
 ("03", "cafe-comptoir-abel", "Café Comptoir Abel", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 20,
  "On Rue Guynemer in Ainay, at the old shopfront with the name painted above it."),
 ("04", "le-bouchon-des-filles", "Le Bouchon des Filles", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark"], 20,
  "On Rue Sergent Blandan, at number twenty, below the slopes of the Croix-Rousse."),
 ("05", "la-mere-brazier", "La Mère Brazier", "foodAndDrink",
  ["Venue", "Food", "History", "Iconic Landmark"], 20,
  "On Rue Royale, at number twelve, the corner building with the discreet sign."),
 ("06", "ombellule", "Ombellule", "foodAndDrink",
  ["Venue", "Food", "Immigration", "Contemporary"], 20,
  "On Cours Franklin Roosevelt, outside number thirty-six, near the Foch metro."),
 ("07", "l-antiquaire", "L'Antiquaire", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Hidden Gem"], 20,
  "On Rue Hippolyte Flandrin, at number twenty: a dark frontage and low light behind the glass."),
 ("08", "le-fantome-de-l-opera", "Le Fantôme de l'Opéra", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Literature"], 20,
  "On Rue Royale, at number nineteen, the small dark frontage north of the opera house."),
 ("09", "mokxa", "Mokxa", "foodAndDrink",
  ["Venue", "Food", "Commerce", "Immigration"], 20,
  "On Rue Victor Fort, on the Croix-Rousse plateau, at the café with Mokxa over the door."),
 ("10", "la-commune", "La Commune", "foodAndDrink",
  ["Venue", "Food", "After Dark", "History", DM, "Déborah Hirigoyen"], 30,
  "On Rue Pré-Gaudry in Gerland, at the long, low workshop with big doors and a terrace."),
 ("11", "le-sucre", "Le Sucre", "musicAndPerformance",
  ["Venue", "Performance", "After Dark", "Waterfront", "Maritime", "Viewpoint"], 40,
  "On Quai Rambaud, the Saône behind you, facing La Sucrière with the club on its roof."),
 ("12", "intercontinental-hotel-dieu", "InterContinental Lyon – Hôtel-Dieu", "history",
  ["Notable Building", "Venue", "History", "Waterfront", "Neoclassical", "Iconic Landmark", DM, "Jacques-Germain Soufflot"], 60,
  "On Quai Jules Courmont, the Rhône at your back, facing the long facade and its dome."),
 ("13", "cour-des-loges", "Cour des Loges", "history",
  ["Notable Building", "Venue", "History", "Commerce", "Hidden Gem"], 20,
  "On Rue du Bœuf, at number six, before the old stone doorway into the courtyards."),
 ("14", "villa-florentine", "Villa Florentine", "hiddenGems",
  ["Venue", "Faith", "History", "Viewpoint", "Hidden Gem"], 30,
  "On the Montée Saint-Barthélémy, looking up at the villa set into the slope of Fourvière."),
 ("15", "mob-hotel", "MOB Hotel Lyon", "architecture",
  ["Venue", "Food", "Waterfront", "Contemporary"], 30,
  "On Quai Rambaud, facing the chocolate-coloured cubes behind a perforated metal facade."),
 ("16", "couvent-de-la-tourette", "Convent of La Tourette | Couvent Sainte-Marie de La Tourette", "architecture",
  ["Religious Building", "Faith", "Architecture", "Brutalist", "Iconic Landmark", DM, "Le Corbusier", "Iannis Xenakis"], 60,
  "On the slope below the convent at Éveux, the concrete block raised on its thin columns.", "Éveux"),
 ("17", "musee-des-confluences", "Confluences Museum | Musée des Confluences", "architecture",
  ["Museum", "Architecture", "Waterfront", "Contemporary", "Iconic Landmark", DM, "Coop Himmelb(l)au"], 60,
  "At the tip of the Presqu'île, where the Rhône and the Saône meet, below the crystal and the cloud."),
 ("18", "cite-musee-tony-garnier", "Tony Garnier Urban Museum | Cité Musée Tony Garnier", "visualArt",
  ["Museum", "Public Art", "Art", "Architecture", "History", "Free to Visit", DM, "Tony Garnier"], 50,
  "On Rue des Serpollières, among the blocks of flats with murals on their end walls."),
 ("19", "opera-de-lyon", "Lyon Opera House | Opéra de Lyon", "musicAndPerformance",
  ["Venue", "Performance", "Architecture", "Neoclassical", "Contemporary", "After Dark", "Iconic Landmark", DM,
   "Jean Nouvel", "Antoine-Marie Chenavard", "Jean-Marie Pollet"], 40,
  "On Place de la Comédie, facing the stone front and the black glass vault on top."),
 ("20", "lugdunum", "Lugdunum", "history",
  ["Museum", "History", "Architecture", "Brutalist", "Viewpoint", DM, "Bernard Zehrfuss"], 40,
  "On Rue Cléberg near the top of Fourvière, above the two Roman theatres cut into the slope."),
 ("21", "hotel-de-ville-de-villeurbanne", "Villeurbanne Town Hall | Hôtel de Ville de Villeurbanne", "architecture",
  ["Civic", "District", "Architecture", "Power", "History", "Art Deco", DM, "Robert Giroud", "Môrice Leroux"], 50,
  "On Place Lazare Goujon, facing the pale town hall and its tall clock tower.", "Villeurbanne"),
 ("22", "gare-saint-exupery-tgv", "Lyon Saint-Exupéry TGV Station | Gare de Lyon Saint-Exupéry TGV", "architecture",
  ["Notable Building", "Engineering", "Architecture", "Contemporary", "Iconic Landmark", DM, "Santiago Calatrava"], 60,
  "On the station forecourt by the airport, below the steel and glass roof spreading its wings.", "Colombier-Saugnieu"),
 ("23", "institut-lumiere", "Institut Lumière", "history",
  ["Museum", "Venue", "History", "Art", "Iconic Landmark"], 40,
  "On Rue du Premier Film in Monplaisir, between the ornate villa and the long, plain hangar."),
 ("24", "cour-des-voraces", "Cour des Voraces", "history",
  ["Notable Building", "History", "Power", "Hidden Gem", "Free to Visit"], 25,
  "Through the doorway at number nine, Place Colbert, below the great open staircase."),
 ("25", "tour-rose", "Pink Tower | Tour Rose (Maison du Crible)", "architecture",
  ["Tower", "History", "Architecture", "Commerce", "Hidden Gem", "Free to Visit"], 20,
  "Through the doorway at sixteen Rue du Bœuf, in the courtyard below the pink stair tower."),
 ("26", "mur-des-canuts", "Silk Weavers' Wall | Mur des Canuts", "visualArt",
  ["Public Art", "Notable Building", "Art", "History", "Free to Visit", "Iconic Landmark"], 40,
  "At Boulevard des Canuts and Rue Denfert-Rochereau, facing the painted Croix-Rousse street."),
 ("27", "jardin-rosa-mir", "Rosa Mir Garden | Jardin Rosa Mir", "hiddenGems",
  ["Park", "Art", "Faith", "Immigration", "Green Escape", "Hidden Gem"], 25,
  "Outside number eighty-seven, Grande Rue de la Croix-Rousse, the doorway to the shell garden."),
 ("28", "jardin-des-curiosites", "Garden of Curiosities | Jardin des Curiosités", "natureAndParks",
  ["Park", "Viewpoint", "Public Art", "Art", "Green Escape", "Free to Visit", "Hidden Gem"], 40,
  "In the walled garden at the end of Place de Montréal, by the six chairs and the view."),
 ("29", "cube-orange", "Orange Cube | Cube Orange", "architecture",
  ["Notable Building", "Architecture", "Waterfront", "Contemporary", DM, "Jakob + MacFarlane"], 40,
  "On Quai Rambaud, facing the orange block with the great round hole cut through it."),
 ("30", "parc-de-la-tete-d-or", "Tête d'Or Park | Parc de la Tête d'Or", "natureAndParks",
  ["Park", "Green Escape", "History", "Free to Visit", "Iconic Landmark", DM, "Denis & Eugène Bühler"], 60,
  "At the gilded Porte des Enfants du Rhône on Place du Général Leclerc, the lake ahead."),
 ("31", "passage-thiaffait", "Passage Thiaffait", "hiddenGems",
  ["Notable Building", "Fashion", "Commerce", "History", "Hidden Gem", "Free to Visit"], 25,
  "On Rue René Leynaud, at the portico into the curving passage of little shopfronts."),
 ("32", "le-bal-des-ardents", "Librairie Le Bal des Ardents", "literature",
  ["Venue", "Literature", "Commerce", "Hidden Gem"], 20,
  "On Rue Neuve, at number seventeen, before the archway built out of books."),
 ("33", "pralus-monplaisir", "Pralus Lyon – Monplaisir", "foodAndDrink",
  ["Venue", "Food", "Commerce", "History"], 20,
  "On Avenue des Frères Lumière, at the window of golden brioches studded with pink praline."),
 ("34", "marche-de-la-creation", "Creators' Market | Marché de la Création", "visualArt",
  ["Market", "Art", "Commerce", "Waterfront", "Free to Visit"], 60,
  "On Quai Romain Rolland, the Saône beside you, among the Sunday stalls of artists and makers."),
]

# Contributor-approved (2026-11-14): the supplied point was ~125 m west of the building, on the slope;
# moved onto the convent (OSM node "Couvent de la Tourette").
COORD_OVERRIDE = {
    "couvent-de-la-tourette": (45.8220812, 4.6253229),
}
SKIP_IMAGES = {"l-antiquaire": (6,)}  # _6 is byte-identical to _5
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
                   and int(re.search(r"_(\d+)o?\.webp$", w).group(1)) not in SKIP_IMAGES.get(slug, ())),
                  key=lambda w: int(re.search(r"_(\d+)o?\.webp$", w).group(1)))
    stem = f"lys-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"lys:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": LYS_ID,
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
        "city": spec[7] if len(spec) > 7 else CITY,
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
    assert len({s[1] for s in SPEC}) == len(SPEC) == 34
    assert len({s[0] for s in SPEC}) == 34
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
    if not any(m["id"] == LYS_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio NCE")
        data["makers"].insert(prev + 1, {
            "id": LYS_ID, "displayName": "Atlas Studio LYS", "platform": "dozent", "handle": "atlas.lys",
            "avatarURL": None, "avatarEmoji": "🇫🇷",
            "bio": "Atlas Studio's Lyon bureau — the city the mères lyonnaises taught to eat: bouchons, quenelles "
                   "and a market named for Paul Bocuse; the silk weavers' traboules of the Croix-Rousse and the "
                   "Renaissance courtyards of Saint-Jean; and the architecture that keeps arriving, from Tony "
                   "Garnier's model city to Jean Nouvel's opera roof and Le Corbusier's convent at La Tourette.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {LYS_ID}")


if __name__ == "__main__":
    main()
