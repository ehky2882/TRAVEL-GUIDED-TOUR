#!/usr/bin/env python3
"""Build the Florence (FLR) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/lyon-batch1/tools/wire_lyon.py. Folders are matched by script number
("pv" = the unnumbered Ponte Vecchio folder).

Usage: python3 -I wire_florence.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-18"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Florence"
COUNTRY = "Italy"

FLR_ID = str(uuid.uuid5(NS, "atlas-maker:flr"))

# script no. (or "pv" for the unnumbered Ponte Vecchio), slug, title, category, tags, radius, caption[, city]
SPEC = [
 ("01", "riva-lofts-florence", "Riva Lofts Florence", "hiddenGems",
  ["Notable Building", "Architecture", "Waterfront", "Contemporary", "Hidden Gem", DM, "Claudio Nardi"], 30,
  "On Via Baccio Bandinelli, at the old factory set back behind a garden wall by the river."),
 ("02", "adastra", "AdAstra", "hiddenGems",
  ["Notable Building", "Architecture", "Green Escape", "Hidden Gem", DM, "Francesco Maestrelli"], 25,
  "On Via del Campuccio in the Oltrarno, at the entrance in the long, plain-fronted old mansion."),
 ("03", "hotel-lungarno", "Hotel Lungarno", "hiddenGems",
  ["Notable Building", "Waterfront", "History", "War", "Art", "Viewpoint", DM, "Michele Bönan"], 25,
  "On Borgo San Jacopo, a few steps from the Ponte Vecchio, at the hotel door on the river side."),
 ("04", "villa-cora", "Villa Cora", "history",
  ["Notable Building", "History", "Neoclassical", DM, "Pietro Comparini"], 40,
  "On Viale Machiavelli, at the gates and gravel drive up to the pale neoclassical villa."),
 ("05", "trattoria-sostanza", "Trattoria Sostanza", "foodAndDrink",
  ["Venue", "Food", "History", "Iconic Landmark"], 20,
  "On Via del Porcellana, at the small shopfront with Sostanza over the door and white tiles inside."),
 ("06", "trattoria-mario", "Trattoria Mario", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 20,
  "On Via Rosina by the Mercato Centrale, at the small trattoria with the plain sign reading Mario."),
 ("07", "il-santo-bevitore", "Il Santo Bevitore", "foodAndDrink",
  ["Venue", "Food", "Literature"], 20,
  "On Via di Santo Spirito, at numbers sixty-four and sixty-six, one block back from the river."),
 ("08", "trattoria-cammillo", "Trattoria Cammillo", "foodAndDrink",
  ["Venue", "Food", "History"], 20,
  "On Borgo San Jacopo, at number fifty-seven, the trattoria front with Cammillo over the door."),
 ("09", "locale", "Locale", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark"], 20,
  "On Via delle Seggiole, at number twelve, the old palazzo front with Locale beside the door."),
 ("10", "le-volpi-e-l-uva", "Le Volpi e l'Uva", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 20,
  "In tiny Piazza dei Rossi, off the south end of the Ponte Vecchio, at the corner wine bar."),
 ("11", "ditta-artigianale", "Ditta Artigianale", "foodAndDrink",
  ["Venue", "Food", "Architecture", "Modernist", DM, "Giovanni Michelucci"], 20,
  "On Via dello Sprone, at number five, the wide shopfront near Piazza della Passera."),
 ("12", "rivoire", "Rivoire", "foodAndDrink",
  ["Venue", "Food", "History", "Public Square", "Iconic Landmark"], 25,
  "On Piazza della Signoria, at the café tables facing the tower of the Palazzo Vecchio."),
 ("13", "loggia-palazzo-guadagni", "Loggia Roof Bar, Palazzo Guadagni", "foodAndDrink",
  ["Notable Building", "Architecture", "Food", "Viewpoint", "After Dark"], 30,
  "In Piazza Santo Spirito, facing the corner palazzo at number nine and its open roof loggia."),
 ("14", "officina-santa-maria-novella", "Santa Maria Novella Pharmacy | Officina Profumo-Farmaceutica di Santa Maria Novella", "culturalHeritage",
  ["Notable Building", "Commerce", "History", "Faith", "Iconic Landmark"], 25,
  "On Via della Scala, outside the entrance to the old pharmacy in the convent wall."),
 ("15", "antico-setificio-fiorentino", "Antico Setificio Fiorentino", "culturalHeritage",
  ["Venue", "Commerce", "Fashion", "History", "Hidden Gem"], 20,
  "On Via Lorenzo Bartolini in San Frediano, at number four, the modest door of the silk workshop."),
 ("16", "giulio-giannini-e-figlio", "Giulio Giannini e Figlio", "culturalHeritage",
  ["Venue", "Commerce", "History", "Literature", "Hidden Gem"], 25,
  "On Piazza de' Pitti, your back to the palace, facing the old shopfront at number thirty-seven."),
 ("17", "stefano-bemer", "Stefano Bemer", "culturalHeritage",
  ["Venue", "Commerce", "Fashion", "Hidden Gem"], 20,
  "On Via di San Niccolò, at number two, the tall building with the workshop behind its windows."),
 ("18", "scuola-del-cuoio", "Scuola del Cuoio", "culturalHeritage",
  ["Venue", "Commerce", "Fashion", "History", "War", DM, "Michelozzo"], 15,
  "On Via di San Giuseppe, at the garden entrance on the side of the Basilica of Santa Croce."),
 ("19", "biblioteca-medicea-laurenziana", "Laurentian Library | Biblioteca Medicea Laurenziana", "architecture",
  ["Library", "Architecture", "Iconic Landmark", DM, "Michelangelo", "Bartolomeo Ammannati"], 40,
  "In the cloister of San Lorenzo, by the stair that climbs to the library's vestibule."),
 ("20", "museo-dell-opera-del-duomo", "Opera del Duomo Museum | Museo dell'Opera del Duomo", "visualArt",
  ["Museum", "Art", "Faith", "Engineering", "Iconic Landmark", DM, "Adolfo Natalini"], 40,
  "At the east end of Piazza del Duomo, behind the cathedral's apse, facing number nine."),
 ("21", "museo-novecento", "Museo Novecento", "visualArt",
  ["Museum", "Art", "Contemporary", "Public Art"], 40,
  "In Piazza Santa Maria Novella, the basilica behind you, facing the arcaded loggia at number ten."),
 ("22", "palazzo-strozzi", "Palazzo Strozzi", "architecture",
  ["Notable Building", "Architecture", "Power", "Art", DM, "Giuliano da Sangallo", "Il Cronaca"], 50,
  "On Piazza Strozzi, standing back from the great rough-stone block of the palace."),
 ("23", "museo-stefano-bardini", "Stefano Bardini Museum | Museo Stefano Bardini", "visualArt",
  ["Museum", "Art", "Hidden Gem"], 30,
  "On Via dei Renai by Piazza Demidoff, facing the severe building at number thirty-seven."),
 ("24", "chiostro-dello-scalzo", "Cloister of the Scalzo | Chiostro dello Scalzo", "visualArt",
  ["Religious Building", "Art", "Faith", "Hidden Gem"], 20,
  "On Via Cavour, at number sixty-nine, the plain doorway into the small painted cloister."),
 ("25", "firenze-santa-maria-novella-station", "Santa Maria Novella Station | Stazione di Firenze Santa Maria Novella", "architecture",
  ["Civic", "Architecture", "Modernist", DM, "Giovanni Michelucci"], 60,
  "In Piazza della Stazione, the long, low stone front ahead and Santa Maria Novella behind you."),
 ("26", "stadio-artemio-franchi", "Artemio Franchi Stadium | Stadio Artemio Franchi", "architecture",
  ["Venue", "Architecture", "Engineering", "Modernist", DM, "Pier Luigi Nervi"], 60,
  "In Campo di Marte, by the Marathon Tower at the main entrance and the spiral stairs."),
 ("27", "chiesa-dell-autostrada", "Church of the Motorway | Chiesa dell'Autostrada del Sole", "architecture",
  ["Religious Building", "Architecture", "Remembrance", "Modernist", DM, "Giovanni Michelucci"], 50,
  "By the Firenze Nord exit of the A1 at Campi Bisenzio, below the church's copper tent of a roof.", "Campi Bisenzio"),
 ("28", "cappella-de-pazzi", "Pazzi Chapel | Cappella de' Pazzi", "architecture",
  ["Religious Building", "Architecture", "Faith", DM, "Filippo Brunelleschi"], 15,
  "In the first cloister of Santa Croce, facing the porch of six columns and the small dome."),
 ("29", "basilica-di-san-miniato-al-monte", "San Miniato al Monte | Basilica di San Miniato al Monte", "sacredSites",
  ["Religious Building", "Faith", "Viewpoint", "Iconic Landmark"], 50,
  "At the top of the stairway above Piazzale Michelangelo, facing the white and green marble front."),
 ("30", "ponte-santa-trinita", "Santa Trinita Bridge | Ponte Santa Trinita", "architecture",
  ["Bridge", "Architecture", "Engineering", "War", "Free to Visit", DM, "Bartolomeo Ammannati"], 50,
  "On the Lungarno Corsini, just downstream, looking up at the three flat arches and four statues."),
 ("31", "giardino-bardini", "Bardini Garden | Giardino Bardini", "natureAndParks",
  ["Park", "Art", "Green Escape", "Viewpoint"], 60,
  "At the Via de' Bardi gate at the foot of the hill, or the top gate on Costa San Giorgio."),
 ("32", "le-murate", "Le Murate", "history",
  ["Civic", "History", "Crime", "Public Square", "Free to Visit"], 40,
  "In Piazza delle Murate on Via Ghibellina, below the galleries of old wooden cell doors."),
 ("33", "biblioteca-delle-oblate", "Oblate Library | Biblioteca delle Oblate", "hiddenGems",
  ["Library", "History", "Viewpoint", "Free to Visit", "Hidden Gem"], 25,
  "On Via dell'Oriuolo, at number twenty-six, the entrance to the long medieval library building."),
 ("pv", "ponte-vecchio", "Ponte Vecchio", "history",
  ["Bridge", "Commerce", "History", "Iconic Landmark", "Viewpoint", "Free to Visit"], 40,
  "In the middle of the bridge, at the downstream opening by the bronze bust, facing the water."),
]

# Contributor-approved (2026-11-18): the supplied point was 84 m north-east, across the basilica;
# moved onto the library (OSM node "Biblioteca Medicea Laurenziana", Piazza di San Lorenzo 9).
COORD_OVERRIDE = {
    "biblioteca-medicea-laurenziana": (43.7744207, 11.2537735),
}
# Scuola del Cuoio and the Pazzi Chapel are 32 m apart; both fences are 15 m so they do not overlap.
SKIP_IMAGES = {}
TEXT_FIX = {}


def folder(num):
    pat = "ponte-vecchio_clean.txt" if num == "pv" else f"{num}_*_clean.txt"
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
    num, slug, title, cat, tags, radius, caption = spec[:7]
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
    stem = f"flr-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"flr:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": FLR_ID,
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
    if not any(m["id"] == FLR_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio LYS")
        data["makers"].insert(prev + 1, {
            "id": FLR_ID, "displayName": "Atlas Studio FLR", "platform": "dozent", "handle": "atlas.flr",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Florence bureau — the city that taught Europe to build again: Brunelleschi's "
                   "chapel, Michelangelo's staircase and the bridges of the Arno; the bookbinders, silk weavers "
                   "and shoemakers still at work in the Oltrarno; trattorias that have barely changed their menus "
                   "since the war; and a modern century too, from Michelucci's station to Nervi's stadium.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {FLR_ID}")


if __name__ == "__main__":
    main()
