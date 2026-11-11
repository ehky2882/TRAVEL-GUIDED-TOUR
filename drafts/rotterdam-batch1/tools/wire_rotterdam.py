#!/usr/bin/env python3
"""Build the Rotterdam (RTM) launch + Portugalia Tasca (AMS) from the Dropbox drop.
Writes renamed media into /tmp/claude-0/stage/{audio,images} and merges entries into Tours.json."""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "/tmp/claude-0/drop2/x"  # unzipped drop
STAGE = sys.argv[2] if len(sys.argv) > 2 else "/tmp/claude-0/stage"  # renamed media out
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-10-27"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"

RTM_ID = str(uuid.uuid5(NS, "atlas-maker:rtm"))
AMS_ID = "946d6338-4459-5061-8206-4dc57784629f"

# folder-prefix, script no., slug, title, category, tags, radius, caption, (lat, lon) override
SPEC = [
 ("Arboretum trompenburg", "01", "arboretum-trompenburg", "Arboretum Trompenburg", "natureAndParks",
  ["Park", "History", "Green Escape", "Hidden Gem"], 60,
  "At the entrance pavilion on the Honingerdijk, where the paths begin to fan out between the lawns.", None),
 ("Art Depot Museum", "02", "depot-boijmans-van-beuningen", "Depot Boijmans Van Beuningen", "architecture",
  ["Museum", "Art", "Architecture", "Contemporary", "Iconic Landmark", DM, "MVRDV"], 50,
  "On the Museumpark lawn, far enough back to catch your reflection in the mirrored bowl.", None),
 ("Atelier Van Lieshout", "03", "atelier-van-lieshout", "Atelier Van Lieshout", "visualArt",
  ["Venue", "Art", "Public Art", "Contemporary", "Hidden Gem"], 50,
  "On the Keileweg in Merwe-Vierhavens, by the long port sheds that house Brutus.", None),
 ("Bakehouse", "04", "bakehouse", "Bakehouse", "foodAndDrink",
  ["Venue", "Food", "Immigration", "Hidden Gem"], 40,
  "At numbers 18 to 22 on the 2e Middellandstraat, in front of the wide bakery counters.", None),
 ("Bar Alaska", "05", "bar-alaska", "Bar Alaska", "foodAndDrink",
  ["Food", "Waterfront", "After Dark"], 40,
  "Where the Kerkhoflaan meets the Rotte in Crooswijk, by the terrace on the water.", None),
 ("Bertmans", "06", "bertmans", "Bertmans", "foodAndDrink",
  ["Venue", "Food"], 40,
  "On the Karel Doormanstraat, a short walk from the Schouwburgplein, by the big windows and terrace.", None),
 ("bookstore Donner", "07", "boekhandel-donner", "Donner Bookshop | Boekhandel Donner", "literature",
  ["Notable Building", "Literature", "History", "War", DM, "H. F. Mertens"], 50,
  "On the Coolsingel pavement, a few steps back from the carved central entrance.", None),
 ("CityHub Rotterdam", "08", "cityhub-rotterdam", "CityHub Rotterdam", "hiddenGems",
  ["Notable Building", "Commerce", "Contemporary", "Hidden Gem"], 40,
  "Partway along the Witte de Withstraat, at the single entrance between three neighbouring buildings.", None),
 ("Crave Coffee", "09", "crave-coffee-bakery", "Crave Coffee & Bakery", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 40,
  "On Vogelenzang, a short street in the Maho quarter behind the Hoogstraat.", None),
 ("De Bijenkorf Rotterdam", "10", "de-bijenkorf", "De Bijenkorf", "architecture",
  ["Notable Building", "Architecture", "Commerce", "Modernist", "Public Art", DM, "Marcel Breuer"], 50,
  "On the Coolsingel, far enough back to take in the store and the sculpture beside it.", None),
 ("de Maaskantine", "11", "de-maaskantine", "de Maaskantine", "foodAndDrink",
  ["Food", "Waterfront", "Green Escape"], 50,
  "On the Esch in Rotterdam East, on the strip of sand in front of the canteen, facing the Maas.", None),
 ("Dudok In Het Park", "12", "dudok-in-het-park", "Dudok in het Park", "foodAndDrink",
  ["Food", "History", "Park"], 50,
  "At the edge of Het Park, facing the pale house of De Heuvel across the lawns.", None),
 ("Eiland van Brienenoord", "13", "eiland-van-brienenoord", "Van Brienenoord Island | Eiland van Brienenoord", "natureAndParks",
  ["Park", "Waterfront", "Maritime", "Green Escape", "Hidden Gem"], 60,
  "On the island's main path, with the span of the Van Brienenoord Bridge overhead.", None),
 ("FENIX", "14", "fenix", "FENIX", "culturalHeritage",
  ["Museum", "Immigration", "Maritime", "Architecture", "Contemporary", "Viewpoint", DM, "MAD Architects"], 60,
  "On the Katendrecht waterfront, looking up at the Tornado bursting through the warehouse roof.",
  (51.9020903, 4.4843147)),
 ("Fletcher Boutique Hotel", "15", "fletcher-hotel-slaak", "Fletcher Boutique Hotel Slaak", "architecture",
  ["Notable Building", "Architecture", "History", "Modernist", DM, "Jo Vegter"], 40,
  "On the pavement of the Slaak opposite, taking in the full width of the 1950s printing house.", None),
 ("Frits", "16", "restaurant-frits", "Restaurant Frits", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 40,
  "At Piet Heynsplein 25, on the little square where historic Delfshaven begins.", None),
 ("HAY Rotterdam", "17", "hay-rotterdam", "HAY Rotterdam", "architecture",
  ["Notable Building", "Architecture", "Commerce", "Contemporary", DM, "Rem Koolhaas"], 40,
  "Where the Meent meets the Haagseveer, beneath the stacked glass boxes of the Timmerhuis.", None),
 ("Historische Tuin Schoonoord", "18", "historische-tuin-schoonoord", "Schoonoord Historic Garden | Historische Tuin Schoonoord", "natureAndParks",
  ["Park", "History", "Green Escape", "Hidden Gem", "Free to Visit"], 50,
  "Just inside the gate on the Kievitslaan, where the winding path leads on towards the pond.", None),
 ("Kralingen Lake", "19", "kralingse-plas", "Kralingen Lake | Kralingse Plas", "natureAndParks",
  ["Park", "Waterfront", "History", "Green Escape", "Free to Visit"], 60,
  "On the shore path, with the lake spread out ahead and the two windmills along the edge.", None),
 ("Market Hall", "20", "markthal", "Market Hall | Markthal", "architecture",
  ["Market", "Food", "Architecture", "Contemporary", "Public Art", "Iconic Landmark", DM, "MVRDV"], 50,
  "Inside the arch, among the stalls, under the painted Horn of Plenty ceiling.", None),
 ("NAI Booksellers", "21", "nai-booksellers", "NAI Booksellers", "literature",
  ["Venue", "Literature", "Architecture", "Contemporary", DM, "Jo Coenen"], 50,
  "In the lobby of Het Nieuwe Instituut on the Museumpark, beside the pond.", None),
 ("Nederlands Fotomuseum", "22", "nederlands-fotomuseum", "Dutch National Museum of Photography | Nederlands Fotomuseum", "visualArt",
  ["Museum", "Art", "Maritime", "History", "Stok & Kanters"], 50,
  "On the Katendrecht side of the Rijnhaven, facing the tall brick Santos warehouse.", None),
 ("OX Rotterdam", "23", "ox-rotterdam", "OX Rotterdam", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Hidden Gem"], 40,
  "At Schiekade 189, beneath the Schieblock, a few minutes' walk from Rotterdam Centraal.", None),
 ("Phil", "24", "phil", "Phil", "foodAndDrink",
  ["Venue", "Food"], 40,
  "At Stadhoudersweg 96D in Blijdorp, at the bright café and shop.", None),
 ("Room Mate Bruno", "26", "room-mate-bruno", "Room Mate Bruno", "history",
  ["Notable Building", "History", "Maritime", "Commerce", "Waterfront"], 40,
  "With your back to the Rijnhaven, looking up at the Pakhuismeesteren warehouse on the Wilhelminakade.", None),
 ("Supernova Hotel", "27", "supernova-hotel", "Supernova Hotel", "architecture",
  ["Notable Building", "Architecture", "Contemporary", "Zondervan Architectuur"], 40,
  "At 's-Gravendijkwal 68, by the hotel's bright, eclectic front.", (51.916468, 4.4631211)),
 ("TorenTuin", "28", "torentuin", "TorenTuin", "foodAndDrink",
  ["Food", "Religious Building", "Hidden Gem"], 40,
  "Across the Lisplein from the pond, at the terrace of the Church of the Resurrection.", None),
 ("Van Maanenbad", "29", "van-maanenbad", "Van Maanenbad", "history",
  ["Notable Building", "History", "Art Deco", DM, "De Roos & Overeijnder"], 40,
  "At the Van Maanenstraat entrance, under the iron letters that spell Sportfondsenbad.", None),
]
AMS = ("Portugalia Tasca", "25", "portugalia-tasca", "Portugalia Tasca", "foodAndDrink",
       ["Venue", "Food", "Hidden Gem"], 40,
       "At Bakkersstraat 12, on the short lane between the Rembrandtplein and the Amstel.", None)

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
        "country": "Netherlands",
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }

def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    new = [build(s, "rtm", "rtm", RTM_ID, "Rotterdam") for s in SPEC]
    new.append(build(AMS, "ams", "ams", AMS_ID, "Amsterdam"))
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == RTM_ID for m in data["makers"]):
        lil = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio LIL")
        data["makers"].insert(lil + 1, {
            "id": RTM_ID, "displayName": "Atlas Studio RTM", "platform": "dozent", "handle": "atlas.rtm",
            "avatarURL": None, "avatarEmoji": "🇳🇱",
            "bio": "Atlas Studio's Rotterdam bureau — the port city that rebuilt itself after 1940 and never stopped "
                   "experimenting, where coffee and tea warehouses have become museums and hotels, a market hall wears "
                   "apartments for a roof, and the kitchens run from a Middellandstraat bakery to a hidden basement speakeasy.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {RTM_ID}")

if __name__ == "__main__":
    main()
