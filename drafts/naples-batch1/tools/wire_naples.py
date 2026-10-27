#!/usr/bin/env python3
"""Build the Naples (NAP) launch from the Dropbox drop.
Writes renamed media into /tmp/claude-0/stage/{audio,images} and merges entries into Tours.json."""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"  # unzipped drop
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"  # renamed media out
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-10-27"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"

NAP_ID = str(uuid.uuid5(NS, "atlas-maker:nap"))
# photos dropped on the contributor's instruction (they show the Certosa di San Martino, not the castle)
SKIP = {"castel-santelmo_4.webp", "castel-santelmo_6.webp"}

# folder-prefix, script no., slug, title, category, tags, radius, caption, (lat, lon) override
SPEC = [
 ("Atelier In", "01", "atelier-ines-arts-suites", "Atelier Inès Arts & Suites", "visualArt",
  ["Venue", "Art", "Commerce", "Hidden Gem"], 20,
  "On Via dei Cristallini in the Sanità, at the tall pitch-pine gates of the house.", None),
 ("Casa D'Anna", "02", "casa-danna-ai-cristallini", "Casa D'Anna ai Cristallini", "hiddenGems",
  ["Notable Building", "Art", "History", "Hidden Gem"], 20,
  "Halfway along Via dei Cristallini, at the old palazzo doorway of Palazzo Giannattasio.", None),
 ("Castel Sant'Elmo", "03", "castel-sant-elmo", "Castel Sant'Elmo", "history",
  ["Museum", "History", "War", "Power", "Viewpoint", "Iconic Landmark", DM, "Pedro Luis Escrivá"], 60,
  "On the ramp across the moat to the main gate, with the Vomero behind you.", None),
 ("Doctor Vintage", "04", "doctor-vintage", "Doctor Vintage", "hiddenGems",
  ["Venue", "Fashion", "Commerce", "Hidden Gem"], 40,
  "On Via Giuseppe Fiorelli in Chiaia, at the small shopfront at number 12.",
  (40.8349908844937, 14.239130067750816)),
 ("Ex Chiesa", "05", "ex-chiesa-santa-maria-della-misericordia-ai-vergini",
  "Former Church of Santa Maria della Misericordia ai Vergini | Ex Chiesa di Santa Maria della Misericordia ai Vergini",
  "sacredSites", ["Religious Building", "Faith", "Art", "Baroque", "Contemporary", "Hidden Gem"], 40,
  "At the corner of Via Misericordiella, before the carved grey piperno doorway.", None),
 ("Ex voto", "06", "ex-voto", "Ex Voto", "hiddenGems",
  ["Venue", "Fashion", "Commerce", "Faith", "Hidden Gem"], 40,
  "At number 18A Via Carlo Poerio, one street in from the Riviera di Chiaia.", None),
 ("Ipogeo", "07", "ipogeo-dei-cristallini", "Cristallini Hypogeum | Ipogeo dei Cristallini", "culturalHeritage",
  ["Museum", "History", "Art", "Hidden Gem"], 20,
  "At the doorway of number 133 Via dei Cristallini, where the guided groups gather.", None),
 ("L'Antiquario", "08", "lantiquario", "L'Antiquario", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Hidden Gem"], 40,
  "On the little lane of Vannella Gaetani, at the discreet door of number 2.", None),
 ("Mim", "09", "mimi-alla-ferrovia", "Mimì alla Ferrovia", "foodAndDrink",
  ["Venue", "Food", "History", "Iconic Landmark"], 40,
  "On Via Alfonso d'Aragona near Napoli Centrale, under the restaurant's name over the door.", None),
 ("Neapolitan sacred art", "10", "neapolitan-sacred-art-fabio-paolella", "Neapolitan Sacred Art di Fabio Paolella", "visualArt",
  ["Venue", "Art", "Faith", "Commerce", "Hidden Gem"], 40,
  "In the quiet lanes around Via Anticaglia, at the small workshop window full of figures.", None),
 ("Officina", "11", "officina-ba-bar", "Officina Ba-Bar", "foodAndDrink",
  ["Venue", "Food", "Maritime", "After Dark"], 40,
  "At number 169 Via Santa Lucia, by the black-fronted bar and its pavement tables.", None),
 ("Pescheria Azzurra", "12", "pescheria-azzurra", "Pescheria Azzurra", "foodAndDrink",
  ["Market", "Food", "Commerce", "Maritime"], 40,
  "Where Via Portamedina meets the Pignasecca market, at the fish counters facing the street.", None),
 ("Pizzeria Concettina", "13", "pizzeria-concettina-ai-tre-santi", "Pizzeria Concettina ai Tre Santi", "foodAndDrink",
  ["Venue", "Food", "History", "Iconic Landmark"], 40,
  "On Via Arena della Sanità, where the small crowd waits outside the pizzeria.", None),
 ("Riccardodalisi", "14", "riccardo-dalisi-rua-catalana", "Riccardo Dalisi, Rua Catalana", "visualArt",
  ["District", "Public Art", "Art", "Commerce", "History", "Free to Visit", "Hidden Gem"], 50,
  "On narrow Rua Catalana, looking up at the iron and tin figures fixed to the palazzi.", None),
 ("Royal Continental", "15", "royal-continental-hotel", "Royal Continental Hotel", "architecture",
  ["Notable Building", "Architecture", "Modernist", "Waterfront", "War", DM, "Gio Ponti", "Ferdinando Chiaramonte"], 50,
  "On Via Partenope, facing the long modern block across the road from the Castel dell'Ovo.", None),
 ("San Carlo Theatre", "16", "teatro-di-san-carlo", "San Carlo Theatre | Teatro di San Carlo", "musicAndPerformance",
  ["Venue", "Performance", "Architecture", "Neoclassical", "Power", "Iconic Landmark", DM,
   "Giovanni Antonio Medrano", "Antonio Niccolini"], 50,
  "On Via San Carlo, between the theatre's arcaded front and the Galleria Umberto I.", None),
 ("Scotto Jonno", "17", "scottojonno", "ScottoJonno", "foodAndDrink",
  ["Venue", "Food", "Performance", "History", "Hidden Gem"], 40,
  "Inside the Galleria Principe di Napoli, across the road from the Archaeological Museum.", None),
 ("SuperOtium", "18", "superotium", "SuperOtium", "visualArt",
  ["Notable Building", "Art", "Contemporary", "Hidden Gem"], 40,
  "Beside the long red front of the National Archaeological Museum, at a modest street-level sign.", None),
 ("Vineria Bandita", "19", "vineria-bandita", "Vineria Bandita", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 40,
  "At number 57 Via Michele Kerbaker, on one of the Vomero's busy shopping streets.", None),
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
    new = [build(s, "nap", "nap", NAP_ID, "Naples") for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == NAP_ID for m in data["makers"]):
        rtm = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio RTM")
        data["makers"].insert(rtm + 1, {
            "id": NAP_ID, "displayName": "Atlas Studio NAP", "platform": "dozent", "handle": "atlas.nap",
            "avatarURL": None, "avatarEmoji": "🇮🇹",
            "bio": "Atlas Studio's Naples bureau — a city of painted Greek tombs and Bourbon opera, star forts and "
                   "station trattorias, where the Sanità's palazzi hide guesthouses and galleries, Rua Catalana still "
                   "works in tin, and the pizza is sometimes paid for by a stranger.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {NAP_ID}")

if __name__ == "__main__":
    main()
