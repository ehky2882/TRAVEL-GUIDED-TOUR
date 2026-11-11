#!/usr/bin/env python3
"""Build the Athens (ATH) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/mecca-batch1/tools/wire_mecca.py.

Usage: python3 -I wire_athens.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-04"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Athens"

ATH_ID = str(uuid.uuid5(NS, "atlas-maker:ath"))

# folder prefix (after "output "), script no., slug, title, category, tags, radius, caption
SPEC = [
 ("Perianth Hotel", "01", "perianth-hotel", "Perianth Hotel", "architecture",
  ["Notable Building", "Architecture", "Contemporary", "Hidden Gem", DM, "K-Studio"], 25,
  "On Agias Irinis Square by the flower stalls, before the curving grey façade with its banded balconies."),
 ("Shila", "02", "shila", "Shila", "visualArt",
  ["Notable Building", "Art", "Neoclassical", "Hidden Gem"], 25,
  "On Mantzarou Street, a pedestrian lane one block from Kolonaki Square, before the neoclassical townhouse at number 10."),
 ("The Modernist Athens", "03", "the-modernist-athens", "The Modernist Athens", "architecture",
  ["Notable Building", "Architecture", "Modernist", DM, "FORMrelated"], 30,
  "On the lower slopes of Kolonaki, before a clean, symmetrical 1950s building: the former Canadian Embassy."),
 ("Xenodocheio Milos", "04", "xenodocheio-milos", "Xenodocheio Milos | Ξενοδοχείο Milos", "architecture",
  ["Notable Building", "Architecture", "Neoclassical"], 25,
  "At the corner of Kolokotroni and Voulis, with the Old Parliament behind you, facing the twin neoclassical buildings."),
 ("Hotel Grande Bretagne", "05", "hotel-grande-bretagne", "Hotel Grande Bretagne | Μεγάλη Βρεταννία", "history",
  ["Notable Building", "History", "War", "Power", "Neoclassical", "Iconic Landmark", DM, "Kostas Voutsinas"], 40,
  "On Syntagma Square, facing the big pale building on the north side, with the Parliament up the slope to your right."),
 ("Diporto", "06", "diporto", "Diporto | Δίπορτο", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 25,
  "At the corner of Sokratous and Theatrou, near the central market: two unmarked doorways with stairs going down."),
 ("Karamanlidika tou Fani", "07", "karamanlidika-tou-fani", "Karamanlidika tou Fani | Καραμανλίδικα του Φάνη",
  "foodAndDrink", ["Venue", "Food", "Immigration", "History"], 25,
  "At the corner of Sokratous and Evripidou, off Athinas Street: half delicatessen, half restaurant."),
 ("Seychelles", "08", "seychelles", "Seychelles", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "In Metaxourgeio, at the corner of Kerameikou Street and little Avdi Square, in a century-old corner building."),
 ("Atlantikos", "09", "atlantikos", "Atlantikos | Ατλαντικός", "foodAndDrink",
  ["Venue", "Food", "Maritime"], 25,
  "On Avliton Street in Psyrri, between Thiseio and Monastiraki: tables out in the lane and lifebuoys upstairs."),
 ("Nolan", "10", "nolan", "Nolan", "foodAndDrink",
  ["Venue", "Food"], 25,
  "On Voulis Street, a few minutes south of Syntagma Square, outside numbers 31 to 33."),
 ("The Clumsies", "11", "the-clumsies", "The Clumsies", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "On Praxitelous Street in the commercial centre, outside number 30: a restored building with big windows."),
 ("Brettos", "12", "brettos", "Brettos | Μπρέττος", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark"], 25,
  "On Kydathineon Street in Plaka, before the narrow bar with its back wall of glowing coloured bottles."),
 ("Couleur Locale", "13", "couleur-locale", "Couleur Locale", "foodAndDrink",
  ["Venue", "Food", "Viewpoint", "After Dark", "Hidden Gem"], 25,
  "At Normanou 3, off Ermou in Monastiraki: go in through the antique shop and take the lift to the roof."),
 ("Baba au Rum", "14", "baba-au-rum", "Baba au Rum", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "On Klitiou Street, a narrow lane in the centre, outside the small modernist-looking bar."),
 ("Taf Coffee", "15", "taf-coffee", "Taf Coffee", "foodAndDrink",
  ["Venue", "Food"], 25,
  "On Emmanouil Benaki Street at the edge of Exarchia, outside numbers 7 to 9: a café and roaster."),
 ("Melissinos Art", "16", "melissinos-art", "Melissinos Art — The Poet Sandal Maker", "culturalHeritage",
  ["Venue", "Literature", "Fashion", "Commerce", "Hidden Gem"], 25,
  "On Tzireon Street in Makrygianni, behind the Acropolis Museum, outside number 16."),
 ("Kombologadiko", "17", "kombologadiko", "Kombologadiko | Κομπολογάδικο", "culturalHeritage",
  ["Venue", "Commerce", "Hidden Gem"], 25,
  "On Amerikis Street between Stadiou and Panepistimiou, outside number 9: a window full of worry beads."),
 ("Forget Me Not", "18", "forget-me-not", "Forget Me Not", "hiddenGems",
  ["Venue", "Commerce", "Art"], 25,
  "On Adrianou Street in Plaka, beneath the Acropolis, outside number 100."),
 ("Varvakios Central Municipal Market", "19", "varvakios-central-market",
  "Varvakios Central Market | Βαρβάκειος Αγορά", "foodAndDrink",
  ["Market", "Food", "Commerce", "History", "Free to Visit"], 50,
  "On Athinas Street, before the covered market that fills the block to Sofokleous, Evripidou and Aiolou."),
 ("Little Tree Books", "20", "little-tree-books-and-coffee", "Little Tree Books & Coffee", "foodAndDrink",
  ["Venue", "Food", "Literature", "Hidden Gem"], 25,
  "On Kavalloti Street in Koukaki, a couple of minutes from the Acropolis Museum, outside number 2."),
 ("Pikionis Paths", "21", "pikionis-paths-loumbardiaris",
  "Pikionis Paths & Agios Dimitrios Loumbardiaris | Άγιος Δημήτριος Λουμπαρδιάρης", "architecture",
  ["Religious Building", "Park", "Architecture", "Modernist", "Viewpoint", "Free to Visit", DM,
   "Dimitris Pikionis"], 50,
  "On the paved path up Philopappou Hill, opposite the Acropolis, by the little church of Agios Dimitrios."),
 ("Acropolis Museum", "22", "acropolis-museum", "Acropolis Museum | Μουσείο Ακρόπολης", "architecture",
  ["Museum", "Architecture", "History", "Contemporary", "Iconic Landmark", DM, "Bernard Tschumi",
   "Michael Photiadis"], 50,
  "On the forecourt off Dionysiou Areopagitou, at the foot of the Acropolis, above the glass-floored excavation."),
 ("Stavros Niarchos", "23", "snfcc",
  "Stavros Niarchos Foundation Cultural Center | Κέντρο Πολιτισμού Ίδρυμα Σταύρος Νιάρχος", "architecture",
  ["Library", "Venue", "Park", "Architecture", "Performance", "Contemporary", "Viewpoint", "Free to Visit", DM,
   "Renzo Piano"], 80,
  "At the foot of the sloping park in Kallithea, near the sea at Faliro, looking up to the floating white canopy."),
 ("National Museum of Contemporary Art", "24", "emst",
  "National Museum of Contemporary Art (EMST) | Εθνικό Μουσείο Σύγχρονης Τέχνης", "architecture",
  ["Museum", "Art", "Architecture", "Modernist", DM, "Takis Zenetos"], 50,
  "On Syngrou Avenue at Kallirrois, before the long, low former Fix brewery with its bands of windows."),
 ("Benaki Museum", "25", "benaki-pireos-138", "Benaki Museum — Pireos 138 | Μουσείο Μπενάκη — Πειραιώς 138", "visualArt",
  ["Museum", "Art", "Architecture", "Contemporary"], 40,
  "On Pireos Street, the old industrial road to the port, outside number 138."),
 ("Athens Conservatoire", "27", "athens-conservatoire", "Athens Conservatoire | Ωδείο Αθηνών", "architecture",
  ["Venue", "Architecture", "Performance", "Modernist", "Brutalist", "Hidden Gem", DM, "Ioannis Despotopoulos"], 50,
  "At the corner of Rigillis and Vasileos Konstantinou, before the long raw-concrete building along the avenue."),
 ("Conrad Athens", "28", "conrad-athens-the-ilisian", "Conrad Athens The Ilisian", "architecture",
  ["Notable Building", "Architecture", "Art", "Modernist", "Public Art", DM, "Emmanouil Vourekas",
   "Prokopis Vasileiadis", "Antonis Georgiadis", "Spyros Staikos"], 50,
  "On Vasilissis Sofias Avenue, across from the long, gently curved white slab of the former Athens Hilton."),
 ("Anafiotika", "29", "anafiotika", "Anafiotika | Αναφιώτικα", "culturalHeritage",
  ["District", "History", "Immigration", "Hidden Gem", "Free to Visit"], 60,
  "In the whitewashed lanes high on the north-east side of the Acropolis rock, above Plaka."),
 ("Lycabettus Funicular", "30", "lycabettus-funicular", "Lycabettus Funicular | Τελεφερίκ Λυκαβηττού",
  "natureAndParks", ["Park", "Engineering", "Viewpoint"], 30,
  "At the lower station at the top of Ploutarchou Street in Kolonaki, where it meets Aristippou."),
]

# The drop's point for the funicular sits ~20 m up the slope; the contributor asked for the ascending
# (lower) station, which OSM has as "Καλωδιοκίνητος Σιδηρόδρομος Λυκαβηττού - Σταθμός Ανάβασης", Aristippou 1.
COORD_OVERRIDE = {"lycabettus-funicular": (37.9803157, 23.7440055)}
CITY_OVERRIDE = {"snfcc": "Kallithea"}


def folder(prefix):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and os.path.basename(d).startswith("output " + prefix)]
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
    if len(s) <= n:
        return s
    return s[:n].rsplit(" ", 1)[0].rstrip(",;:") + "…"


def duration(mp3):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", mp3])
    return round(float(out))


def build(spec):
    pre, num, slug, title, cat, tags, radius, caption = spec
    d = folder(pre)
    lat, lon = COORD_OVERRIDE.get(slug, coords(d))
    script = [s for s in glob.glob(f"{d}/athens_{num}_*.txt") if not s.endswith("_TTS.txt")]; assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    hero = [w for w in webps if w.endswith("hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if w not in hero),
                  key=lambda w: int(re.search(r"(\d+)\.webp$", w).group(1)))
    stem = f"ath-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"ath:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": ATH_ID,
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
        "city": CITY_OVERRIDE.get(slug, CITY),
        "country": "Greece",
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
    if not any(m["id"] == ATH_ID for m in data["makers"]):
        mak = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio MAK")
        data["makers"].insert(mak + 1, {
            "id": ATH_ID, "displayName": "Atlas Studio ATH", "platform": "dozent", "handle": "atlas.ath",
            "avatarURL": None, "avatarEmoji": "🇬🇷",
            "bio": "Atlas Studio's Athens bureau — the museum built on stilts beneath the Parthenon, the stone paths "
                   "of Pikionis, an island village on the side of the Acropolis, a Bauhaus dream left unfinished, "
                   "basement tavernas with no sign over the door, and some of the best bars in the world.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {ATH_ID}")


if __name__ == "__main__":
    main()
