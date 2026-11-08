#!/usr/bin/env python3
"""Build the Fukuoka (FUK) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/mexico-city-batch1/tools/wire_mexico_city.py. Folders are matched by script number
(folder names arrived with #Uxxxx escapes for non-ASCII letters, e.g. B·B·B).

Usage: python3 -I wire_fukuoka.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-08"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Fukuoka"

FUK_ID = str(uuid.uuid5(NS, "atlas-maker:fuk"))

# script no., slug, title, category, tags, radius, caption[, city]
SPEC = [
 ("01", "hotel-il-palazzo", "Hotel Il Palazzo | ホテル イル・パラッツォ", "architecture",
  ["Notable Building", "Architecture", "Contemporary", "After Dark", DM, "Aldo Rossi", "Shigeru Uchida"], 30,
  "In the open square on the Haruyoshi side of the Naka River, facing the long wall of deep red travertine."),
 ("02", "the-ritz-carlton-fukuoka", "The Ritz-Carlton, Fukuoka | ザ・リッツ・カールトン福岡", "architecture",
  ["Tower", "Architecture", "History", "Contemporary", "Free to Visit", "Kume Sekkei"], 40,
  "In the plaza at the foot of the glass tower, the old 1929 Daimyo Elementary School in one corner."),
 ("03", "hilton-fukuoka-sea-hawk", "Hilton Fukuoka Sea Hawk | ヒルトン福岡シーホーク", "architecture",
  ["Tower", "Waterfront", "Architecture", "Maritime", "Contemporary", DM, "César Pelli"], 50,
  "On the waterfront by the baseball dome, taking in the 36-storey ship-shaped tower facing Hakata Bay."),
 ("04", "ganso-nagahamaya", "Ganso Nagahamaya | 元祖長浜屋", "foodAndDrink",
  ["Venue", "Food", "History", "After Dark"], 25,
  "In Nagahama by the fish market: the queue, the ticket machine and the long steaming counter."),
 ("05", "hakata-issou", "Hakata Issou | 博多一双", "foodAndDrink",
  ["Venue", "Food"], 25,
  "On a side street east of Hakata Station among office blocks, at the ramen shop with the queue outside."),
 ("06", "udon-taira", "Udon Taira | うどん平", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 25,
  "In Sumiyoshi south of Canal City, a small shop on the ground floor of a block of flats; lunch only."),
 ("07", "yanagibashi-rengo-market", "Yanagibashi Rengo Market | 柳橋連合市場", "foodAndDrink",
  ["Market", "Food", "Commerce", "History", "Hidden Gem"], 50,
  "At the entrance to the covered market by the Yanagi bridge, a hundred-metre lane of counters."),
 ("08", "nakasu-yatai", "Nakasu Yatai | 中洲屋台", "foodAndDrink",
  ["Waterfront", "Food", "After Dark", "Iconic Landmark"], 50,
  "On the Nakasu riverside walkway of the Naka River, along the row of curtained street-food stalls."),
 ("09", "coffee-bimi", "Coffee Bimi | 珈琲美美", "foodAndDrink",
  ["Venue", "Food", "History", "Hidden Gem"], 25,
  "On a quiet street in Akasaka west of Tenjin, where a short queue forms on the pavement around midday."),
 ("10", "manu-coffee-haruyoshi", "manu coffee Haruyoshi", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "On Watanabe-dori, at the ground floor of a tower on the Haruyoshi side: an eighteen-seat café."),
 ("11", "rec-coffee-yakuin-ekimae", "REC COFFEE Yakuin Ekimae", "foodAndDrink",
  ["Venue", "Food", "After Dark"], 25,
  "At street level near Nishitetsu Yakuin Station, under the REC sign: the original shop."),
 ("12", "bbb-potters", "B·B·B POTTERS", "hiddenGems",
  ["Venue", "Commerce", "Hidden Gem"], 25,
  "In Yakuin, at the homeware shop filling the ground and first floors of its building."),
 ("13", "books-kubrick-hakozaki", "BOOKS KUBRICK Hakozaki | ブックスキューブリック 箱崎店", "literature",
  ["Venue", "Literature", "Commerce", "Hidden Gem"], 25,
  "Just west of JR Hakozaki Station: the street-level bookshop, with a café and gallery upstairs."),
 ("14", "ishimura-manseido-main-store", "Ishimura Manseido Main Store | 石村萬盛堂 本店", "foodAndDrink",
  ["Venue", "Food", "History", "Commerce"], 25,
  "At 2-1 Suzaki-machi on the old Hakata side, the corner where the Yamakasa floats turn each July."),
 ("15", "kawabata-shopping-arcade", "Kawabata Shopping Arcade | 川端商店街", "culturalHeritage",
  ["Market", "Commerce", "History", "Free to Visit"], 50,
  "In the small square partway along the covered arcade, by the festival float and the zenzai shop."),
 ("16", "fukuoka-art-museum", "Fukuoka Art Museum | 福岡市美術館", "visualArt",
  ["Museum", "Art", "Architecture", "Modernist", DM, "Kunio Maekawa"], 40,
  "On the broad approach up from Ohori Park, the lake behind you and the long, low tiled walls ahead."),
 ("17", "kushida-shrine", "Kushida Shrine | 櫛田神社", "sacredSites",
  ["Religious Building", "Faith", "History", "Iconic Landmark", "Free to Visit"], 40,
  "Through the main gate from the street, the halls ahead and a towering festival float in the grounds."),
 ("18", "shofukuji", "Shofukuji | 聖福寺", "sacredSites",
  ["Religious Building", "Faith", "History", "Hidden Gem", "Free to Visit"], 50,
  "At the outer gate, looking down the straight path to the inner gate, Buddha hall and abbot's quarters."),
 ("19", "hakata-machiya-furusato-kan", "Hakata Machiya Furusato-kan | 博多町家ふるさと館", "culturalHeritage",
  ["Museum", "History", "Hidden Gem"], 30,
  "Across the street from Kushida Shrine, at the wooden Meiji-era weaver's townhouse and its neighbours."),
 ("20", "fukuoka-asian-art-museum", "Fukuoka Asian Art Museum | 福岡アジア美術館", "visualArt",
  ["Museum", "Art", "Contemporary"], 40,
  "At Hakata Riverain beside the Hakata River; the museum is high up in the building, by lift."),
 ("21", "kyushu-national-museum", "Kyushu National Museum | 九州国立博物館", "history",
  ["Museum", "History", "Architecture", "Contemporary", DM, "Kiyonori Kikutake", "Kume Sekkei"], 60,
  "Out of the colour-lit tunnel from Dazaifu Tenmangu, facing the long glass curve and its blue wave roof.",
  "Dazaifu"),
 ("22", "acros-fukuoka", "ACROS Fukuoka | アクロス福岡", "architecture",
  ["Civic", "Park", "Architecture", "Green Escape", "Viewpoint", "Free to Visit", "Iconic Landmark", DM,
   "Emilio Ambasz", "Nihon Sekkei"], 50,
  "On the lawn of Tenjin Central Park facing north, the stepped green terraces climbing to the roof."),
 ("23", "tenjin-business-center", "Tenjin Business Center | 天神ビジネスセンター", "architecture",
  ["Tower", "Architecture", "Contemporary", DM, "Rem Koolhaas", "Shohei Shigematsu"], 40,
  "On the corner of Meiji-dori, looking up at the glass tower with its pixelated, stepped corners."),
 ("24", "fukuoka-bank-head-office", "Fukuoka Bank Head Office | 福岡銀行本店", "architecture",
  ["Notable Building", "Architecture", "Modernist", "Free to Visit", DM, "Kisho Kurokawa"], 40,
  "On the Tenjin pavement, looking up at the dark granite block raised over its open public plaza."),
 ("25", "tenjin-underground-mall", "Tenjin Underground Mall | 天神地下街", "architecture",
  ["Market", "Commerce", "Architecture", "Free to Visit"], 60,
  "Down any stairway from Watanabe-dori, in the dim passage of stone floors and arabesque ceilings."),
 ("26", "former-fukuoka-prefectural-public-hall-guest-house",
  "Former Fukuoka Prefectural Public Hall Guest House | 旧福岡県公会堂貴賓館", "culturalHeritage",
  ["Notable Building", "Architecture", "History"], 30,
  "At the river corner of Tenjin Central Park, before the wooden 1910 building with its octagonal tower."),
 ("27", "fukuoka-city-red-brick-cultural-center", "Fukuoka City Red Brick Cultural Center | 福岡市赤煉瓦文化館",
  "architecture",
  ["Notable Building", "Architecture", "History", "Free to Visit", DM, "Kingo Tatsuno", "Yasushi Kataoka"], 30,
  "Across the street from the red brick and white granite building with its dome and eight-sided turret."),
 ("28", "canal-city-hakata", "Canal City Hakata | キャナルシティ博多", "architecture",
  ["Notable Building", "Commerce", "Architecture", "Contemporary", "Iconic Landmark", DM, "Jon Jerde"], 60,
  "On the lowest level at the water's edge, the curving canal and its coloured balconies all around."),
 ("29", "nexus-world", "Nexus World | ネクサスワールド", "architecture",
  ["District", "Architecture", "Contemporary", "Hidden Gem", DM, "Arata Isozaki", "Rem Koolhaas", "Steven Holl",
   "Christian de Portzamparc", "Mark Mack", "Oscar Tusquets", "Osamu Ishiyama"], 60,
  "On a quiet residential street in Kashii; these are private homes, so look from the street."),
 ("30", "island-city-central-park-grin-grin", "Island City Central Park Grin Grin | アイランドシティ中央公園 ぐりんぐりん",
  "architecture",
  ["Park", "Architecture", "Green Escape", "Contemporary", DM, "Toyo Ito"], 50,
  "On the path beside the long pond, facing three low rounded shells rising from the grass."),
]

COORD_OVERRIDE = {
    # was 112 m north, in Komondo-machi on Daikoku-dori; GSI house-number point for 2-1 Suzaki-machi
    # (the address the contributor confirmed, 2026-11-08)
    "ishimura-manseido-main-store": (33.595943, 130.404434),
}

SKIP_IMAGES = {}


def folder(num):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and glob.glob(f"{d}/{num}_*_clean.txt")]
    assert len(m) == 1, (num, m)
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
    stem = f"fuk-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"fuk:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": FUK_ID,
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
        "country": "Japan",
        "relatedTourIds": [],
        "primaryCategory": cat,
        "tags": tags,
        "priceUSD": 0,
    }


def main():
    data = json.load(open(CAT, encoding="utf-8"))
    ids = {t["id"] for t in data["tours"]}
    assert len({s[1] for s in SPEC}) == len(SPEC) == 30
    assert len({s[0] for s in SPEC}) == 30
    new = [build(s) for s in SPEC]
    for t in new:
        assert t["id"] not in ids, ("id collision", t["title"])
    if not any(m["id"] == FUK_ID for m in data["makers"]):
        mex = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio MEX")
        data["makers"].insert(mex + 1, {
            "id": FUK_ID, "displayName": "Atlas Studio FUK", "platform": "dozent", "handle": "atlas.fuk",
            "avatarURL": None, "avatarEmoji": "🇯🇵",
            "bio": "Atlas Studio's Fukuoka bureau — a hill of trees laid over an office block, Aldo Rossi's red "
                   "stone palazzo, a river run through a shopping centre, six architects' housing by the bay, "
                   "Japan's first Zen temple, the festival float that never leaves Kushida Shrine, and the "
                   "riverside street stalls wheeled in every evening.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {FUK_ID}")


if __name__ == "__main__":
    main()
