#!/usr/bin/env python3
"""Build the Mecca (MAK) launch from the Dropbox drop.
Writes renamed media into <stage>/{audio,images} and merges entries into Tours.json.
Adapted from drafts/valencia-batch1/tools/wire_valencia.py.

Usage: python3 -I wire_mecca.py <unzipped drop> <stage dir>   (run once: refuses colliding ids)"""
import json, os, re, shutil, subprocess, sys, uuid, glob

DROP = sys.argv[1] if len(sys.argv) > 1 else "drop/x"
STAGE = sys.argv[2] if len(sys.argv) > 2 else "stage"
CAT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../TRAVEL GUIDED TOUR/Resources/Tours.json")
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
TODAY = "2026-11-02"
NS = uuid.NAMESPACE_URL
DM = "Designed by a Master"
CITY = "Mecca"

MAK_ID = str(uuid.uuid5(NS, "atlas-maker:mak"))

# folder prefix, script no., slug, title, category, tags, radius, caption
SPEC = [
 ("Masjid al-Haram", "16", "masjid-al-haram", "Masjid al-Haram | المسجد الحرام", "sacredSites",
  ["Religious Building", "Faith", "Architecture", "History", "Iconic Landmark", DM,
   "Mimar Sinan", "Mohamed Kamal Ismail"], 80,
  "On the great plaza south of the mosque, facing the King Abdulaziz Gate with the Clock Towers at your back."),
 ("Al Kaaba", "33", "kaaba", "The Kaaba | الكعبة", "sacredSites",
  ["Religious Building", "Faith", "History", "Iconic Landmark"], 60,
  "At the parapet of an upper level of the mataf, looking down on the Kaaba and the ring of pilgrims."),
 ("Safaa and Marwah", "17", "safa-and-marwa", "Safa and Marwa | الصفا والمروة", "sacredSites",
  ["Religious Building", "Faith", "History", "Architecture"], 60,
  "At one end of the Mas'a, the long enclosed gallery of the sa'i on the mosque's eastern side."),
 ("Makkah Al Mukarramah Library", "18", "makkah-al-mukarramah-library",
  "Makkah Al Mukarramah Library | مكتبة مكة المكرمة", "history",
  ["Library", "Faith", "History", "Hidden Gem"], 40,
  "On the open plaza east of the mosque by the Safa end, before a plain two-storey building facing west."),
 ("Masjid al Jinn", "26", "masjid-al-jinn", "Masjid al-Jinn | مسجد الجن", "sacredSites",
  ["Religious Building", "Faith", "History", "Hidden Gem"], 40,
  "On Al Masjid Al Haram Road in Al-Hajun, about 900 m north of the Grand Mosque, beside the Mu'alla cemetery."),
 ("Al Muallaa Cemetery", "27", "al-muallaa-cemetery", "Al Muallaa Cemetery | مقبرة المعلاة", "sacredSites",
  ["Monument", "Faith", "History", "Remembrance"], 80,
  "At the gates of Jannat al-Mu'alla in Al-Hajun, on the northern approach to the Grand Mosque."),
 ("Tuwa Well", "25", "tuwa-well", "Tuwa Well | بئر طوى", "history",
  ["Monument", "Faith", "History", "Hidden Gem"], 40,
  "In the Jarwal district north-west of the mosque, before a modest enclosure around an old well."),
 ("Bay#U2019ah Mosque", "24", "bayah-mosque", "Bay'ah Mosque | مسجد البيعة", "sacredSites",
  ["Religious Building", "Faith", "History", "Hidden Gem"], 40,
  "In Mina, below the slopes near the Jamarat Bridge, before a small walled mosque with an open courtyard."),
 ("Aisha Al Rajhi Mosque", "28", "aisha-al-rajhi-mosque", "Aisha Al Rajhi Mosque | مسجد عائشة الراجحي", "sacredSites",
  ["Religious Building", "Faith", "Architecture", "Contemporary"], 50,
  "In Al-Naseem, about 4 km east of the Haram, at the foot of the two tall minarets beside Arak Park."),
 ("Jamaraat Bridge", "29", "jamarat-bridge", "Jamarat Bridge | جسر الجمرات", "sacredSites",
  ["Bridge", "Faith", "Engineering", "Remembrance", "Contemporary", DM, "Dar Al-Handasah"], 100,
  "At the western end of the Mina valley, before the long multi-level bridge and its wide ramps."),
 ("Mt Arafat", "37", "mount-arafat", "Mount Arafat | جبل عرفات", "sacredSites",
  ["Park", "Faith", "History", "Iconic Landmark", "Viewpoint", "Free to Visit"], 100,
  "On the plain of Arafat, about 20 km south-east of Makkah, with the pillar on the hill's summit as your landmark."),
 ("Hira Cave", "23", "hira-cave-mount-of-light", "Hira Cave, Mount of Light | غار حراء، جبل النور", "sacredSites",
  ["Park", "Faith", "History", "Iconic Landmark", "Viewpoint"], 60,
  "On the path up Jabal al-Nour on the eastern side of Makkah, with the Hira Cultural District below you."),
 ("Jabal Thawr", "32", "jabal-thawr", "Jabal Thawr | جبل ثور", "sacredSites",
  ["Park", "Faith", "History", "Viewpoint"], 100,
  "At the foot of the steep rocky peak beyond Misfalah, about 8 km south of the Grand Mosque."),
 ("Hira Cultural District", "22", "hira-cultural-district", "Hira Cultural District | حي حراء الثقافي",
  "culturalHeritage", ["District", "Museum", "Faith", "Contemporary"], 80,
  "In the open plaza at the centre of the district, at the base of Jabal al-Nour."),
 ("Mecca Museum", "21", "mecca-museum", "Mecca Museum | متحف مكة", "history",
  ["Museum", "History", "Art", "Notable Building"], 50,
  "On Al Madinah Al Munawarah Road in Az-Zahir, before the carved-stone Al-Zahir Palace in its gardens."),
 ("Exhibition of the Two Holy Mosques", "19", "exhibition-two-holy-mosques-architecture",
  "Exhibition of the Two Holy Mosques Architecture | معرض عمارة الحرمين الشريفين", "culturalHeritage",
  ["Museum", "Architecture", "Faith", "History", "Hidden Gem"], 50,
  "In Umm al-Joud on the western edge of the city, beside the Kiswa factory."),
 ("Makkah Clock Tower", "34", "makkah-clock-tower", "Makkah Clock Tower | برج ساعة مكة", "architecture",
  ["Tower", "Museum", "Viewpoint", "Engineering", "Iconic Landmark", "Contemporary"], 20,
  "The Clock Tower Museum fills the top four floors behind the clock faces; open to Muslim visitors with a ticket."),
 ("Fairmont Makkah Clock Royal Tower", "02", "makkah-clock-royal-tower-fairmont",
  "Makkah Clock Royal Tower, a Fairmont Hotel", "architecture",
  ["Tower", "Notable Building", "Engineering", "Commerce", "Contemporary"], 30,
  "On the plaza south of the mosque, looking up at the tallest of the seven towers and its four clock faces."),
 ("Raffles Makkah Palace", "01", "raffles-makkah-palace", "Raffles Makkah Palace", "architecture",
  ["Notable Building", "Commerce", "Viewpoint", "Contemporary"], 20,
  "In the Clock Towers cluster on the south side of the plaza, facing the King Abdulaziz Gate."),
 ("Conrad Jabal Omar Makkah", "03", "conrad-jabal-omar-makkah", "Conrad Jabal Omar Makkah", "architecture",
  ["Notable Building", "Commerce", "History", "Contemporary"], 40,
  "On Jabal Omar Street, just south-west of the mosque plaza, before a pair of hotel towers."),
 ("Abraj Al-Bait Shopping Center", "15", "abraj-al-bait-shopping-center",
  "Abraj Al-Bait Shopping Center | مركز أبراج البيت التجاري", "architecture",
  ["Notable Building", "Commerce", "History", "Contemporary"], 30,
  "Just inside the podium of the Clock Towers, on the south side of the plaza opposite the King Abdulaziz Gate."),
 ("Haramain High Speed Railway", "30", "haramain-high-speed-railway-makkah",
  "Haramain High Speed Railway, Makkah Station | محطة قطار الحرمين السريع – مكة", "architecture",
  ["Notable Building", "Engineering", "Contemporary", DM, "Norman Foster"], 80,
  "In the concourse of the station in Ar-Rusayfah, by the Third Ring Road, under the vaulted steel trees."),
 ("Mecca Gate", "31", "mecca-gate", "Mecca Gate | بوابة مكة", "architecture",
  ["Monument", "Public Art", "Faith", "Modernist", DM, "Samir Elabd"], 80,
  "Over the Jeddah to Makkah expressway on the western approach: a concrete Qur'an on its book stand."),
 ("Abdul Samad Al Qurashi", "14", "abdul-samad-al-qurashi", "Abdul Samad Al Qurashi | عبدالصمد القرشي",
  "culturalHeritage", ["Venue", "Commerce", "History"], 20,
  "In the Abraj Al Bait shopping floors beneath the Clock Tower, on the south side of the mosque plaza."),
 ("Cafe Moment", "10", "cafe-moment", "Cafe Moment", "foodAndDrink",
  ["Venue", "Food", "Viewpoint"], 30,
  "On the second floor of the shopping complex opposite the Swissôtel, near the Clock Tower; ask a shopkeeper."),
 ("Al Romansiah", "08", "al-romansiah", "Al Romansiah | الرومانسية", "foodAndDrink",
  ["Venue", "Food"], 40,
  "On Al Masjid Al Haram Road in Al Mursalat, on the eastern side of the city towards Mina."),
 ("Asante Roastery", "12", "asante-roastery", "Asante Roastery | محمصة اسانتي", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 40,
  "On Ibrahim Al Joufaili Street in Al Awali, a residential district in the south of the city."),
 ("cultivo cafe", "13", "cultivo-cafe-and-roastry", "Cultivo Cafe and Roastry | مقهى ومحمصة كالتيفو", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 40,
  "On Al Qadisiyyah Road in Ar-Rashidiyyah, in the north-east of the city; look for the bilingual sign."),
 ("nootropic cafe", "11", "nootropic-cafe-and-roastery",
  "Nootropic Cafe and Roastery | مقهى ومحمصة نوتروبك", "foodAndDrink",
  ["Venue", "Food", "Hidden Gem"], 40,
  "On Al Hajun Street in Az-Zahir, north-west of the mosque; easy to miss, so watch the shopfronts."),
]


def folder(prefix):
    m = [d for d in glob.glob(f"{DROP}/*") if os.path.isdir(d) and os.path.basename(d).startswith(prefix)]
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
    lat, lon = coords(d)
    script = glob.glob(f"{d}/{num}_*_clean.txt"); assert len(script) == 1, (d, script)
    ps = paras(script[0])
    mp3 = glob.glob(f"{d}/*.mp3"); assert len(mp3) == 1
    webps = glob.glob(f"{d}/*.webp")
    hero = [w for w in webps if w.endswith("hero.webp")]; assert len(hero) == 1, d
    rest = sorted((w for w in webps if w not in hero),
                  key=lambda w: int(re.search(r"(\d+)\.webp$", w).group(1)))
    stem = f"mak-{slug}"
    os.makedirs(f"{STAGE}/audio", exist_ok=True); os.makedirs(f"{STAGE}/images", exist_ok=True)
    shutil.copyfile(mp3[0], f"{STAGE}/audio/{stem}.mp3")
    shutil.copyfile(hero[0], f"{STAGE}/images/{stem}_hero.webp")
    extra = []
    for i, w in enumerate(rest, start=2):
        shutil.copyfile(w, f"{STAGE}/images/{stem}_{i}.webp")
        extra.append(f"{BASE}images/{stem}_{i}.webp")
    dur = duration(mp3[0])
    key = f"mak:{stem}"
    hero_url = f"{BASE}images/{stem}_hero.webp"
    return {
        "id": str(uuid.uuid5(NS, f"atlas-tour:{key}")),
        "createdAt": TODAY,
        "title": title,
        "shortDescription": short(ps[0]),
        "longDescription": ps[0] + "\n\n" + ps[2],
        "makerId": MAK_ID,
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
        "country": "Saudi Arabia",
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
    if not any(m["id"] == MAK_ID for m in data["makers"]):
        vlc = next(i for i, m in enumerate(data["makers"]) if m["displayName"] == "Atlas Studio VLC")
        data["makers"].insert(vlc + 1, {
            "id": MAK_ID, "displayName": "Atlas Studio MAK", "platform": "dozent", "handle": "atlas.mak",
            "avatarURL": None, "avatarEmoji": "🇸🇦",
            "bio": "Atlas Studio's Makkah bureau — the Kaaba and the Sacred Mosque that has grown around it for "
                   "fourteen centuries, the hills of Safa and Marwa, the caves of Hira and Thawr, the plain of "
                   "Arafat, a clock tower six hundred metres high, and the coffee roasters where the city's "
                   "residents meet.",
            "websiteURL": None})
    data["tours"].extend(new)
    with open(CAT, "wb") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n")
    print(f"added {len(new)} tours; maker {MAK_ID}")


if __name__ == "__main__":
    main()
