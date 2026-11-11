#!/usr/bin/env python3
"""Build the Turin (TRN) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json."""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"  # unzipped drop
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"  # renamed media out
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-10-29"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"

TRN_ID = str(uuid.uuid5(NS, "atlas-maker:trn"))
SKIP = set()

# folder-prefix, script no., slug, title, category, tags, radius, caption, (lat, lon) override
SPEC = [
 ("Caff#U00e8 - Gelateria", "01", "caffe-gelateria-pepino", "Caffè-Gelateria Pepino", "foodAndDrink",
  ["Venue", "Food", "History", "Iconic Landmark"], 30,
  "At number 8 Piazza Carignano, facing the curving brick front of Palazzo Carignano.", None),
 ("Caff#U00e8 Mulassano", "02", "caffe-mulassano", "Caffè Mulassano", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 40,
  "Under the arcades of Piazza Castello, a few doors from the entrance to the Galleria Subalpina.", None),
 ("Caff#U00e8 Platti", "03", "caffe-platti", "Caffè Platti", "foodAndDrink",
  ["Venue", "Food", "History", "Literature"], 40,
  "On the corner of Corso Vittorio Emanuele II and Corso Re Umberto, under the gold lettering.", None),
 ("Casa Mollino", "04", "casa-mollino", "Casa Mollino", "architecture",
  ["Museum", "Architecture", "Art", "Modernist", "Hidden Gem", DM, "Carlo Mollino"], 40,
  "At the street door on Via Napione, close to the river, below the villa's tall upper windows.", None),
 ("Casa Scaccabarozzi", "05", "casa-scaccabarozzi", "Casa Scaccabarozzi", "architecture",
  ["Notable Building", "Architecture", "Engineering", "Free to Visit", "Hidden Gem", DM, "Alessandro Antonelli"], 40,
  "At the corner of Corso San Maurizio and Via Giulia di Barolo, facing the block's narrow end.", None),
 ("Dealers Association", "06", "balon", "Balôn Flea Market | Mercato del Balôn", "culturalHeritage",
  ["Market", "District", "Commerce", "History", "Free to Visit"], 50,
  "On Via Borgo Dora, among the stalls and dealers' shops running down towards the Cortile del Maglio.", None),
 ("Ferrero1947", "07", "ferrero1947", "Ferrero1947", "hiddenGems",
  ["Venue", "Commerce", "Contemporary", "Hidden Gem"], 40,
  "Outside number 15 Corso Matteotti, by the showroom windows set out like rooms.", None),
 ("Floris House", "08", "floris-house", "Floris House", "hiddenGems",
  ["Venue", "Commerce", "Food", "Hidden Gem"], 40,
  "At the discreet stone doorway of a nineteenth-century palazzo in the historic centre.", None),
 ("Fondazione Sandretto", "09", "fondazione-sandretto-re-rebaudengo",
  "Sandretto Re Rebaudengo Foundation | Fondazione Sandretto Re Rebaudengo", "visualArt",
  ["Museum", "Art", "Contemporary", DM, "Claudio Silvestrin"], 40,
  "At number 16 Via Modane in Borgo San Paolo, before the long, low, plain building.", None),
 ("Galleria Gilibert", "10", "galleria-gilibert", "Galleria Gilibert", "literature",
  ["Venue", "Literature", "Commerce", "History", "Hidden Gem"], 20,
  "Inside the Galleria Subalpina at number 17, by the dark wood and old glass shopfront.", None),
 ("Hotel Victoria", "11", "hotel-victoria", "Hotel Victoria", "hiddenGems",
  ["Venue", "Art", "Hidden Gem"], 40,
  "On the far pavement of quiet Via Nino Costa, facing the frontage of number 4.", None),
 ("Intesa Sanpaolo", "12", "intesa-sanpaolo-skyscraper",
  "Intesa Sanpaolo Skyscraper | Grattacielo Intesa Sanpaolo", "architecture",
  ["Tower", "Architecture", "Engineering", "Contemporary", "Viewpoint", "Iconic Landmark", DM, "Renzo Piano"], 50,
  "On the raised plaza beside Corso Inghilterra, with Porta Susa station's glass roof to the north-east.", None),
 ("Libreria Internazionale", "13", "libreria-internazionale-luxemburg", "Libreria Internazionale Luxemburg",
  "literature", ["Venue", "Literature", "Commerce", "History", "LGBTQ+"], 20,
  "At the corner of Via Accademia delle Scienze and Via Cesare Battisti, by the windows of books.", None),
 ("Libreria L'ibrida", "14", "libreria-librida-bottega", "Libreria L'ibrida Bottega", "literature",
  ["Venue", "Literature", "Commerce", "Hidden Gem"], 40,
  "On Corso Casale at Via Felice Romani in Borgo Po, a few steps from the Gran Madre di Dio.", None),
 ("Madamador", "15", "madamadore", "Madamadorè", "hiddenGems",
  ["Venue", "Commerce", "History", "Hidden Gem"], 40,
  "At number 43 Via Giolitti, by windows full of fabric swatches and rolls of wallpaper.", None),
 # the drop's point sat on Via Revel; the contributor gave the address as Corso Vittorio Emanuele II 86 (courtyard)
 ("Marco Polo", "16", "marco-polo", "Marco Polo", "hiddenGems",
  ["Venue", "Fashion", "Art", "Commerce", "Hidden Gem"], 40,
  "Through the carriage arch of number 86 Corso Vittorio Emanuele II, in the inner courtyard.",
  (45.0661078, 7.6703748)),
 ("Mole Antonelliana", "17", "mole-antonelliana", "Mole Antonelliana", "architecture",
  ["Tower", "Museum", "Architecture", "Engineering", "Faith", "Performance", "Viewpoint", "Iconic Landmark",
   DM, "Alessandro Antonelli"], 50,
  "On the far side of Via Montebello, backed up far enough to take in the whole dome and spire.", None),
 ("Museo Egizio", "19", "museo-egizio", "Egyptian Museum | Museo Egizio", "culturalHeritage",
  ["Museum", "History", "Art", "Iconic Landmark"], 40,
  "At number 6 Via Accademia delle Scienze, before the long baroque brick front beside Piazza Carignano.", None),
 ("Museo Nazionale del Risorgimento", "20", "museo-nazionale-del-risorgimento",
  "National Museum of the Italian Risorgimento | Museo Nazionale del Risorgimento Italiano", "history",
  ["Museum", "History", "Power", "Baroque", "Iconic Landmark", DM, "Guarino Guarini"], 40,
  "In Piazza Carlo Alberto, by the king's statue, facing the columned back of Palazzo Carignano.", None),
 ("Museo Nazionale della Montagna", "21", "museo-nazionale-della-montagna",
  "National Mountain Museum | Museo Nazionale della Montagna", "culturalHeritage",
  ["Museum", "History", "Viewpoint", "Green Escape"], 50,
  "On the terrace before the Capuchin church at the top of Monte dei Cappuccini, looking west.", None),
 ("Pastry Gustavo", "22", "pfatisch", "Pfatisch Pastry Shop | Pasticceria Pfatisch", "foodAndDrink",
  ["Venue", "Food", "History", DM, "Pietro Fenoglio"], 40,
  "Across from number 42 Via Sacchi, south of Porta Nuova, below the Art Nouveau curves and ironwork.", None),
 ("PAVIA & PAVIA", "23", "pavia-pavia-international-design", "Pavia & Pavia International Design", "hiddenGems",
  ["Venue", "Commerce", "Art", "Hidden Gem"], 40,
  "At number 1 Piazza Bodoni, beside the gardens and the Verdi Conservatory.", None),
 ("Piano 35", "24", "piano-35-lounge-bar", "Piano 35 Lounge Bar", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Viewpoint", "Contemporary"], 20,
  "At the top of the Intesa Sanpaolo skyscraper, on the greenhouse's uppermost level.", None),
 ("Porta Palazzo", "25", "porta-palazzo", "Porta Palazzo", "foodAndDrink",
  ["Market", "Public Square", "Food", "Commerce", "Immigration", "Baroque", "Free to Visit", "Iconic Landmark",
   DM, "Filippo Juvarra"], 60,
  "Among the stalls of Piazza della Repubblica, near the iron clock pavilion.", None),
 ("San Carlo Dal 1973", "26", "san-carlo-dal-1973", "San Carlo dal 1973", "hiddenGems",
  ["Venue", "Fashion", "Commerce", "Hidden Gem"], 40,
  "Under the arcades of Piazza San Carlo at number 161, through into the courtyard of Palazzo Villa.", None),
 ("Tomdesign", "27", "tomdesign", "Tomdesign", "hiddenGems",
  ["Venue", "Commerce", "Architecture", "Hidden Gem"], 40,
  "At number 73B Corso San Maurizio in Vanchiglia, by windows full of lamps.", None),
 ("Tre Galli ", "28", "tre-galli", "Tre Galli", "foodAndDrink",
  ["Venue", "Food", "After Dark", "History"], 40,
  "At number 25 Via Sant'Agostino in the Quadrilatero Romano, by the tables under the street lamps.", None),
 ("Tre Galline", "29", "tre-galline", "Tre Galline", "foodAndDrink",
  ["Venue", "Food", "History"], 40,
  "At number 37 Via Bellezia, below the name painted in red over the doorway.", None),
 ("Verdelilla", "30", "verdelilla", "Verdelilla", "hiddenGems",
  ["Venue", "Fashion", "Commerce"], 40,
  "At number 17 Via Assietta, a quiet street of apartment buildings near Porta Nuova.", None),
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
    webps = [w for w in glob.glob(f"{d}/*.webp") if os.path.basename(w) not in SKIP]
    hero = [w for w in webps if w.endswith("_hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if not w.endswith("_hero.webp")),
                  key=lambda w: int(re.search(r"_(\d+)o?\.webp$", w).group(1)))
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
        "country": "Italy",
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }

def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    new = [build(s, "trn", "trn", TRN_ID, "Turin") for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == TRN_ID for m in data["makers"]):
        nap = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio NAP")
        data["makers"].insert(nap + 1, {
            "id": TRN_ID, "displayName": "Atlas Studio TRN", "platform": "dozent", "handle": "atlas.trn",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Turin bureau — a city of baroque arcades and mirrored cafés, a synagogue that became "
                   "a cinema museum and a house one slice of polenta wide, where the tramezzino and the gelato on a "
                   "stick were born, and the Alps close the end of every street.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {TRN_ID}")

if __name__ == "__main__":
    main()
