#!/usr/bin/env python3
"""Build the Kuala Lumpur (KUL) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/fukuoka-batch1/tools/wire_fukuoka.py. Folders are matched by script number
(folder names arrive with #Uxxxx escapes for non-ASCII letters, e.g. KLo#U00e9).

Usage: python3 -I wire_kuala_lumpur.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-10"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Kuala Lumpur"
COUNTRY = "Malaysia"

KUL_ID = str(uuid.uuid5(NS, "atlas-maker:kul"))

# script no., slug, title, category, tags, radius, caption
SPEC = [
 ("01", "the-majestic-hotel", "The Majestic Hotel", "history",
  ["Notable Building", "History", "Neoclassical", "Art Deco", "Colonial", DM, "Keys and Dowdeswell"], 40,
  "On Jalan Sultan Hishamuddin, the old station behind you, facing the long pale 1932 facade up the lawn."),
 ("02", "hotel-stripes", "Hotel Stripes", "architecture",
  ["Notable Building", "Architecture", "Contemporary", "Hidden Gem"], 30,
  "On Jalan Kamunting outside the front door, the tall newcomer among low rows of shophouses."),
 ("03", "the-ruma-hotel-and-residences", "The RuMa Hotel and Residences", "architecture",
  ["Notable Building", "Architecture", "Contemporary"], 30,
  "On leafy Jalan Kia Peng, at the entrance: look into the foyer for the round terracotta birdcage."),
 ("04", "kloe-hotel", "KLoé Hotel", "architecture",
  ["Notable Building", "Architecture", "Contemporary", DM, "Domaine Architects"], 30,
  "At 227 Jalan Bukit Bintang, the quiet eastern end: twin towers of bare concrete, brick and timber."),
 ("05", "dewakan", "Dewakan", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 30,
  "At the foot of Naza Tower on Persiaran KLCC; the restaurant is forty-seven storeys up, on the 48th."),
 ("06", "yut-kee", "Yut Kee | 镒记", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 25,
  "At 1 Jalan Kamunting, a three-storey former house; on weekend mornings the queue gives it away."),
 ("07", "sek-yuen", "Sek Yuen | 适苑", "foodAndDrink",
  ["Venue", "Food", "History"], 25,
  "At 313 Jalan Pudu, the standalone building up its steps, with the 1970s extension next door."),
 ("08", "bijan-bar-and-restaurant", "Bijan Bar and Restaurant", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "At 3 Jalan Ceylon, the low colonial-era building with its terrace and bar opening onto the street."),
 ("09", "nasi-lemak-tanglin", "Nasi Lemak Tanglin", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "Inside the Tanglin food centre on Jalan Cenderasari, at stall number six. A queue means you've found it."),
 ("10", "ps150", "PS150", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Hidden Gem"], 25,
  "At 150 Jalan Petaling, the bright toy-shop front; the bar is through a door at the back."),
 ("11", "vcr", "VCR", "foodAndDrink",
  ["Venue", "Food", "Colonial"], 20,
  "On Jalan Galloway, the two-storey house painted black, with coffee drinkers at the outside tables."),
 ("12", "lokl-coffee-co", "LOKL Coffee Co", "foodAndDrink",
  ["Venue", "Food", "Commerce"], 25,
  "At 30 Jalan Tun H.S. Lee near Medan Pasar, the café at street level of a colonial shophouse row."),
 ("13", "ho-kow-hainam-kopitiam", "Ho Kow Hainam Kopitiam | 何九海南茶店", "foodAndDrink",
  ["Venue", "Food", "History"], 15,
  "On Jalan Balai Polis in Chinatown, at the shophouse with the morning queue; Kwai Chai Hong is behind."),
 ("14", "pahit", "Pahit", "foodAndDrink",
  ["Venue", "Food", "After Dark", "Colonial"], 20,
  "At 3 Jalan Sin Chew Kee, a 1920s shophouse on a quiet street between Chinatown and Bukit Bintang."),
 ("15", "bar-trigona", "Bar Trigona", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 30,
  "In the Four Seasons forecourt on Persiaran Petronas, the Petronas Towers filling the sky above."),
 ("16", "heli-lounge-bar", "Heli Lounge Bar", "foodAndDrink",
  ["Venue", "Food", "Viewpoint", "After Dark"], 30,
  "Outside Menara KH on Jalan Sultan Ismail; the flat top is a helipad, reached via the 34th floor."),
 ("17", "zhongshan-building", "Zhongshan Building | Bangunan Zhongshan", "culturalHeritage",
  ["Notable Building", "Art", "Hidden Gem"], 25,
  "On Jalan Rotan in Kampung Attap: three joined 1950s shophouses with a plain mid-century front."),
 ("18", "rexkl", "REXKL", "culturalHeritage",
  ["Venue", "Literature", "Art Deco", DM, "James Robert Vethavanam"], 30,
  "On Jalan Sultan at the edge of Chinatown; stand on the far pavement to take in the old cinema front."),
 ("19", "apw-bangsar", "APW Bangsar", "hiddenGems",
  ["Venue", "Commerce", "Food"], 40,
  "At the very end of Jalan Riong in Bangsar, among the old printing works' sheds and cafés."),
 ("20", "central-market", "Central Market | Pasar Seni", "architecture",
  ["Market", "Commerce", "Art Deco", DM, "T. Y. Lee"], 50,
  "On Jalan Hang Kasturi, facing the long pale-blue and white Art Deco front, Kasturi Walk alongside."),
 ("21", "royal-selangor-visitor-centre", "Royal Selangor Visitor Centre", "culturalHeritage",
  ["Museum", "Commerce"], 40,
  "In Setapak, north of the centre: the company's headquarters and working pewter factory."),
 ("22", "national-mosque", "National Mosque | Masjid Negara", "sacredSites",
  ["Religious Building", "Faith", "Modernist", "Iconic Landmark", DM,
   "Baharuddin Abu Kassim", "Hisham Albakri", "Howard Ashley"], 60,
  "On Jalan Perdana at the edge of the Lake Gardens, before the folded star roof; dress modestly to go in."),
 ("23", "national-museum", "National Museum | Muzium Negara", "history",
  ["Museum", "History", DM, "Ho Kok Hoe"], 50,
  "On Jalan Damansara, facing the long building under its sweeping roof and great mosaic murals."),
 ("24", "islamic-arts-museum-malaysia", "Islamic Arts Museum Malaysia | Muzium Kesenian Islam Malaysia", "visualArt",
  ["Museum", "Art", "Faith"], 40,
  "On Jalan Lembah Perdana near the National Mosque, facing the arched entrance and turquoise domes."),
 ("25", "rumah-penghulu-abu-seman", "Rumah Penghulu Abu Seman", "culturalHeritage",
  ["Notable Building", "Architecture", "History", "Hidden Gem"], 30,
  "In the Badan Warisan garden off Jalan Stonor, before the timber house raised high on stilts."),
 ("26", "old-kuala-lumpur-railway-station", "Old Kuala Lumpur Railway Station | Stesen Keretapi Kuala Lumpur",
  "architecture",
  ["Notable Building", "Colonial", "Engineering", DM, "Arthur Benison Hubback"], 50,
  "On Jalan Sultan Hishamuddin opposite the Majestic, facing the white arcades, domes and chhatris."),
 ("27", "sultan-abdul-samad-building", "Sultan Abdul Samad Building | Bangunan Sultan Abdul Samad", "history",
  ["Civic", "Power", "History", "Colonial", "Iconic Landmark", DM, "A. C. Norman", "R. A. J. Bidwell"], 50,
  "On Dataran Merdeka, the old cricket green, facing the clock tower and copper domes across Jalan Raja."),
 ("28", "masjid-jamek", "Masjid Jamek", "sacredSites",
  ["Religious Building", "Faith", "Colonial", "Waterfront", DM, "Arthur Benison Hubback"], 40,
  "On Jalan Tun Perak where the Gombak meets the Klang: red brick and white stripes among the palms."),
 ("29", "sin-sze-si-ya-temple", "Sin Sze Si Ya Temple | 仙四师爷庙", "sacredSites",
  ["Religious Building", "Faith", "Immigration", "History", "Hidden Gem"], 25,
  "On Lebuh Pudu near Central Market; the temple sits back from the street through a narrow gateway."),
 ("30", "kwai-chai-hong", "Kwai Chai Hong | 鬼仔巷", "hiddenGems",
  ["District", "Art", "History", "Public Art", "Free to Visit"], 15,
  "At the entrance off Lorong Panggung, a narrow mural-painted lane between two rows of shophouses."),
 ("31", "thean-hou-temple", "Thean Hou Temple | 天后宫", "sacredSites",
  ["Religious Building", "Faith", "Viewpoint", "Free to Visit"], 50,
  "On Robson Heights at the gateway, the steps rising to six tiers of red and gold roofs."),
 ("32", "ilham-gallery", "ILHAM Gallery", "visualArt",
  ["Museum", "Art", "Contemporary", "Free to Visit", DM, "Norman Foster"], 30,
  "On the Jalan Binjai plaza at the foot of Ilham Tower; look up at its cross-hatched steel frame."),
 ("33", "national-monument", "National Monument | Tugu Negara", "history",
  ["Monument", "War", "Remembrance", "Public Art", "Free to Visit"], 50,
  "On Jalan Parlimen in the Lake Gardens, facing the bronze soldiers across the reflecting pool."),
 ("34", "national-library-of-malaysia", "National Library of Malaysia | Perpustakaan Negara Malaysia", "architecture",
  ["Library", "Architecture", "Contemporary", DM, "Kumpulan Akitek"], 50,
  "On Jalan Tun Razak, facing the tall peaked roof folded up into points like a headdress."),
 ("35", "menara-tabung-haji", "Menara Tabung Haji", "architecture",
  ["Tower", "Faith", "Modernist", DM, "Hijjas Kasturi"], 40,
  "On Jalan Tun Razak east of the Petronas Towers: the drum-like tower ringed by five white columns."),
 ("36", "menara-tun-perak", "Menara Tun Perak", "architecture",
  ["Tower", "Commerce", "Modernist", DM, "Hijjas Kasturi"], 40,
  "On Jalan Tun Perak at the foot of the white tower, formerly Menara Maybank, with its angled top."),
 ("37", "dayabumi-complex", "Dayabumi Complex | Kompleks Dayabumi", "architecture",
  ["Tower", "Commerce", "Modernist", DM, "Arkitek MAA", "BEP Architects"], 50,
  "Between Central Market and the old station, facing the white tower wrapped in pointed arches."),
 ("38", "parliament-house", "Parliament House | Bangunan Parlimen Malaysia", "architecture",
  ["Civic", "Power", "Modernist", DM, "William Ivor Shipley"], 60,
  "On the approach in the Lake Gardens, before the tall white grilled tower and its low chamber block."),
 ("39", "merdeka-stadium", "Merdeka Stadium | Stadium Merdeka", "history",
  ["Venue", "Power", "History", "Engineering", "Iconic Landmark", DM, "Stanley Jewkes"], 60,
  "On the hill south of Chinatown: the low open stadium and floodlight towers, Merdeka 118 above."),
 ("40", "kl-forest-eco-park", "KL Forest Eco Park | Taman Eko Rimba Kuala Lumpur", "natureAndParks",
  ["Park", "History", "Green Escape", "Free to Visit"], 80,
  "On Bukit Nanas below the KL Tower, under the tall trees just off Jalan Raja Chulan or the tower grounds."),
 ("41", "saloma-link", "Saloma Link", "architecture",
  ["Bridge", "Architecture", "Engineering", "Contemporary", "After Dark", "Free to Visit", DM, "VERITAS Design Group"], 60,
  "Midway along the footbridge, Kampung Baru behind you and the Petronas Towers ahead."),
 ("42", "klcc-park", "KLCC Park", "natureAndParks",
  ["Park", "Architecture", "Green Escape", "Free to Visit", DM, "Roberto Burle Marx"], 80,
  "By the lake at the foot of the Petronas Towers, where you can see both the water and the towers."),
]

COORD_OVERRIDE = {}
SKIP_IMAGES = {}


def folder(num):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and glob.glob(f"{d}/{num}_*_clean.txt")]
    assert len(m) == 1, (num, m)
    return m[0]


def coords(d):
    m = re.search(r"(-?\d+\.\d+),\s*(-?\d+\.\d+)\s*$", d)
    return (round(float(m.group(1)), 7), round(float(m.group(2)), 7))


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
    num, slug, title, cat, tags, radius, caption = spec[:7]
    city = spec[7] if len(spec) > 7 else CITY
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
    stem = f"kul-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"kul:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": KUL_ID,
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
        "country": COUNTRY,
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }


def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    assert len({s[1] for s in SPEC}) == len(SPEC) == 42
    assert len({s[0] for s in SPEC}) == 42
    for s in SPEC:
        assert len(s[6]) <= 110, (s[1], len(s[6]))
    new = [build(s) for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == KUL_ID for m in data["makers"]):
        prev = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio FUK")
        data["makers"].insert(prev + 1, {
            "id": KUL_ID, "displayName": "Atlas Studio KUL", "platform": "dozent", "handle": "atlas.kul",
            "avatarURL": None, "avatarEmoji": "🇲🇾",
            "bio": "Atlas Studio's Kuala Lumpur bureau — a railway station dressed as a Mughal palace, a mosque "
                   "under a folded concrete umbrella, a tower shaped like a sheathed dagger, the stadium where "
                   "independence was declared, rainforest in the middle of the city, Chinatown's back lanes and "
                   "temples, and the kopitiams that have barely changed their menus since the 1920s.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {KUL_ID}")


if __name__ == "__main__":
    main()
