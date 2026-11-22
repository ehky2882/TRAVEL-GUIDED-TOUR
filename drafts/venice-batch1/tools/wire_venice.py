#!/usr/bin/env python3
"""Build the Venice (VCE) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/florence-batch1/tools/wire_florence.py. Folders are matched by script number.

Usage: python3 -I wire_venice.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob, math

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-22"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Venice"
COUNTRY = "Italy"

VCE_ID = str(uuid.uuid5(NS, "atlas-maker:vce"))

# script no., slug, title, category, tags, radius, caption[, city]
SPEC = [
 ("01", "ca-di-dio", "Ca' di Dio", "hiddenGems",
  ["Notable Building", "Waterfront", "History", "Faith", "Hidden Gem", DM, "Jacopo Sansovino", "Patricia Urquiola"], 30,
  "On the Riva degli Schiavoni, lagoon at your back, facing the long pale front by the Rio Ca' di Dio."),
 ("02", "il-palazzo-experimental", "Il Palazzo Experimental", "hiddenGems",
  ["Notable Building", "Architecture", "Waterfront", "Contemporary", "After Dark", DM, "Dorothée Meilichzon"], 25,
  "On the Zattere, the Giudecca Canal behind you, facing the palazzo with three doors side by side."),
 ("03", "aman-venice", "Aman Venice", "hiddenGems",
  ["Notable Building", "History", "Art", "Power", DM, "Gian Giacomo de' Grigi"], 30,
  "On Calle Tiepolo in San Polo, at the land entrance to Palazzo Papadopoli, near the Rialto."),
 ("04", "venissa", "Venissa", "foodAndDrink",
  ["Venue", "Food", "History", "Green Escape", "Hidden Gem"], 40,
  "On Mazzorbo, by the brick walls round the vines and the lone bell tower, near the bridge to Burano."),
 ("05", "the-gritti-palace", "The Gritti Palace", "hiddenGems",
  ["Notable Building", "Waterfront", "History", "Literature", "Power", "Viewpoint", "After Dark"], 30,
  "In Campo Santa Maria del Giglio, at the hotel entrance; the palazzo itself faces the Grand Canal."),
 ("06", "trattoria-antiche-carampane", "Trattoria Antiche Carampane", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 20,
  "On Rio Terà de le Carampane in San Polo, at the low doorway with the name painted above it."),
 ("07", "osteria-alle-testiere", "Osteria alle Testiere", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 20,
  "On Calle del Mondo Novo in Castello, at the very small dining room behind a modest front."),
 ("08", "local", "Local", "foodAndDrink",
  ["Venue", "Food", "Contemporary"], 20,
  "On Salizada dei Greci in Castello, at number 3303, near the leaning tower of San Giorgio dei Greci."),
 ("09", "trattoria-al-gatto-nero", "Trattoria al Gatto Nero", "foodAndDrink",
  ["Venue", "Food", "Waterfront", "Maritime"], 20,
  "On Burano's Fondamenta della Giudecca, at the canalside tables under the black cat sign."),
 ("10", "ca-doro-alla-vedova", "Ca' d'Oro alla Vedova", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 20,
  "Off the Strada Nova by the Ca' d'Oro stop, at the lamplit doorway at the end of the narrow passage."),
 ("11", "cantinone-del-vino-gia-schiavi", "Cantinone del Vino già Schiavi", "foodAndDrink",
  ["Venue", "Food", "Waterfront", "Maritime", "History"], 20,
  "On Fondamenta Nani by the Rio di San Trovaso, facing the gondola yard across the canal."),
 ("12", "al-timon", "Al Timon", "foodAndDrink",
  ["Venue", "Food", "Waterfront", "Maritime", "After Dark"], 20,
  "On the Fondamenta degli Ormesini in Cannaregio, at the bar with an old wooden boat moored in front."),
 ("13", "il-mercante", "Il Mercante", "foodAndDrink",
  ["Venue", "Food", "Commerce", "After Dark"], 20,
  "In Campo dei Frari, the basilica on your left, at the wood-panelled corner bar by the canal."),
 ("14", "caffe-florian", "Caffè Florian", "foodAndDrink",
  ["Venue", "Food", "History", "Art", "Public Square", "Iconic Landmark", DM, "Lodovico Cadorin"], 25,
  "On the south side of Piazza San Marco, under the Procuratie Nuove arcades, at the lit arched windows."),
 ("15", "fortuny-showroom-and-factory", "Fortuny Showroom and Factory", "culturalHeritage",
  ["Venue", "Fashion", "Commerce", "Waterfront", "History", "Hidden Gem"], 30,
  "On Fondamenta San Biagio at the west end of Giudecca, beside the long, low Fortuny building."),
 ("16", "tessitura-luigi-bevilacqua", "Tessitura Luigi Bevilacqua", "culturalHeritage",
  ["Venue", "Commerce", "Fashion", "History", "Hidden Gem"], 20,
  "In Campo San Zan Degolà in Santa Croce, at number 1320, the door marked Luigi Bevilacqua."),
 ("17", "ca-macana", "Ca' Macana", "culturalHeritage",
  ["Venue", "Commerce", "Art", "Hidden Gem"], 20,
  "On Calle de le Botteghe in Dorsoduro, at the shop window crowded with handmade masks."),
 ("18", "libreria-acqua-alta", "Libreria Acqua Alta", "literature",
  ["Venue", "Literature", "Waterfront", "Iconic Landmark"], 20,
  "On Calle Longa Santa Maria Formosa in Castello, at the sign for the high-water bookshop."),
 ("19", "fondazione-querini-stampalia", "Querini Stampalia Foundation | Fondazione Querini Stampalia", "architecture",
  ["Museum", "Library", "Architecture", "Modernist", "Engineering", "Hidden Gem", DM, "Carlo Scarpa"], 25,
  "In Campiello Querini off Campo Santa Maria Formosa, facing Scarpa's bridge across the canal."),
 ("20", "negozio-olivetti", "Olivetti Showroom | Negozio Olivetti", "architecture",
  ["Notable Building", "Architecture", "Commerce", "Modernist", "Public Square", DM, "Carlo Scarpa"], 20,
  "On the north side of Piazza San Marco, under the Procuratie Vecchie, at the narrow Olivetti front."),
 ("21", "punta-della-dogana", "Punta della Dogana", "visualArt",
  ["Museum", "Art", "Contemporary", "Maritime", "Waterfront", "Viewpoint", DM, "Tadao Ando", "Giuseppe Benoni"], 50,
  "At the tip of Dorsoduro where the Grand and Giudecca canals meet, below the golden globe of Fortune."),
 ("22", "fondazione-giorgio-cini", "Giorgio Cini Foundation | Fondazione Giorgio Cini", "history",
  ["Notable Building", "Library", "Art", "History", "Faith", "Hidden Gem", DM, "Andrea Palladio", "Baldassare Longhena"], 35,
  "On the quay of San Giorgio Maggiore, Palladio's church beside you, facing the monastery buildings."),
 ("23", "fondazione-prada", "Fondazione Prada", "visualArt",
  ["Museum", "Art", "Contemporary", "History", "Baroque", DM, "Domenico Rossi"], 30,
  "On Calle de Ca' Corner in Santa Croce, at the land entrance to Ca' Corner della Regina."),
 ("24", "giardini-della-biennale", "Biennale Gardens | Giardini della Biennale", "architecture",
  ["Park", "Art", "Architecture", "Modernist", "Green Escape", DM, "Josef Hoffmann", "Carlo Scarpa", "Sverre Fehn"], 60,
  "At the entrance to the Giardini at the eastern end of Castello, on the waterfront from San Marco."),
 ("25", "basilica-di-san-giorgio-maggiore", "San Giorgio Maggiore | Basilica di San Giorgio Maggiore", "sacredSites",
  ["Religious Building", "Architecture", "Faith", "Art", "Viewpoint", "Iconic Landmark", DM, "Andrea Palladio"], 35,
  "On the quay in front of the basilica on San Giorgio Maggiore, facing back across to San Marco."),
 ("26", "scala-contarini-del-bovolo", "Contarini del Bovolo Staircase | Scala Contarini del Bovolo", "architecture",
  ["Notable Building", "Architecture", "Gothic", "Viewpoint", "Hidden Gem", DM, "Giorgio Spavento"], 20,
  "In Corte Contarini del Bovolo behind Campo Manin, below the spiral of white arches."),
 ("27", "ponte-della-costituzione", "Constitution Bridge | Ponte della Costituzione", "architecture",
  ["Bridge", "Architecture", "Engineering", "Contemporary", "Free to Visit", DM, "Santiago Calatrava"], 40,
  "At the foot of the bridge on the Piazzale Roma side, the station across the Grand Canal."),
 ("28", "entrata-iuav-tolentini", "Iuav Gate at the Tolentini | Ingresso Iuav ai Tolentini", "architecture",
  ["Civic", "Architecture", "Modernist", "Free to Visit", "Hidden Gem", DM, "Carlo Scarpa", "Vincenzo Scamozzi"], 20,
  "In Campazzo dei Tolentini in Santa Croce, at the concrete and stone entrance to the university."),
 ("29", "cimitero-di-san-michele", "San Michele Cemetery | Cimitero di San Michele", "sacredSites",
  ["Religious Building", "Remembrance", "Faith", "Architecture", "Contemporary", DM, "Mauro Codussi", "David Chipperfield"], 50,
  "At the San Michele water bus landing, facing the white church and the cypresses behind the walls."),
 ("30", "st-marks-basilica", "St Mark's Basilica | Basilica di San Marco", "sacredSites",
  ["Religious Building", "Faith", "Power", "Art", "Public Square", "Iconic Landmark"], 50,
  "At the east end of Piazza San Marco, facing the five arched doorways and the bronze horses."),
 ("31", "ponte-di-rialto", "Rialto Bridge | Ponte di Rialto", "history",
  ["Bridge", "Commerce", "History", "Engineering", "Iconic Landmark", "Viewpoint", "Free to Visit", DM, "Antonio da Ponte"], 40,
  "At the top of the bridge, where the two rows of shops part, by the stone balustrade."),
]

# Coordinates are as supplied: Al Timon (15 m from OSM's Fondamenta degli Ormesini 2754) and San Michele
# (60 m from the church, at the landing) were flagged by check-coordinates and checked by hand.
COORD_OVERRIDE = {}
SKIP_IMAGES = {}
TEXT_FIX = {"set into an old wall,.": "set into an old wall."}


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
    stem = f"vce-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"vce:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": VCE_ID,
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
    if not any(m["id"] == VCE_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio FLR")
        data["makers"].insert(prev + 1, {
            "id": VCE_ID, "displayName": "Atlas Studio VCE", "platform": "dozent", "handle": "atlas.vce",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Venice bureau — a city that has spent fifteen hundred years negotiating with "
                   "water: Palladio's white churches facing San Marco, the Rialto and a stolen saint; the velvet "
                   "looms, mask makers and gondola yards still at work; bacari where the counter matters more than "
                   "the table; and Carlo Scarpa, who let the tide in and made it beautiful.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {VCE_ID}")


if __name__ == "__main__":
    main()
