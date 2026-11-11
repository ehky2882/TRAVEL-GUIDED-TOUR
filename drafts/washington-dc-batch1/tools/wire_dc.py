#!/usr/bin/env python3
"""Wire Washington DC (Atlas Studio WAS) into Tours.json: 31 singles + 5 walks.

Adapted from drafts/philadelphia-batch1/tools/wire_philly.py. Differences:
  * durations come from audio-manifest.json, keyed by the published file name;
  * walk slugs come from WALKSLUG (the script filenames do not carry them);
  * a walk stop, the intro included, takes its own picked image when it has one,
    else the hero of the single it revisits; a walk's hero may be a stop key ("W3-4").

Usage (from the repo root):
  python3 drafts/washington-dc-batch1/tools/wire_dc.py --created 2026-11-DD
  python3 drafts/washington-dc-batch1/tools/wire_dc.py --dry-run /tmp/x/Tours.json
"""
import argparse, json, math, os, re, sys, uuid

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
P = f"{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json"
B = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
D = f"{ROOT}/drafts/washington-dc-batch1/"
WD = f"{ROOT}/drafts/washington-dc-walks/"
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U("atlas-maker:was")
CITY = "Washington"


ap = argparse.ArgumentParser()
ap.add_argument("--created", help="createdAt for every tour (launch date, YYYY-MM-DD)")
ap.add_argument("--dry-run", metavar="OUT", help="write to OUT and stand in for missing images")
a = ap.parse_args()
if not a.dry_run and not a.created:
    sys.exit("--created YYYY-MM-DD is required for a real run")

d = json.load(open(P))
assert not any(m["id"] == MAKER for m in d["makers"]), "Atlas Studio WAS is already in the catalogue"
DUR = {k: v["seconds"] for k, v in json.load(open(D + "audio-manifest.json")).items()}


def body(f):
    t = open(f, encoding="utf-8").read().split("\n---\n", 1)[1]
    BEAT = re.compile(r"^\s*\*?\[[^\]]*\]\*?\s*$", re.M)   # [beat] or *[beat]* on its own line
    INLINE = re.compile(r"[ \t]*\*?\[beat\]\*?")                  # a beat at a line's end
    ps = [INLINE.sub("", BEAT.sub("", p)).strip() for p in re.split(r"\n\s*\n", t)]
    return [re.sub(r"\n{2,}", "\n", p) for p in ps if p]


def sentences(p):
    return re.findall(r".+?[.!?](?=\s|$)", p) or [p]


def standpoint(ps):
    for i, p in enumerate(ps):
        if re.match(r"(You should be|You're|You are|Stand at)\b", p):
            return i
    return None


def cut(t, n=145):
    t = re.sub(r"\s+", " ", t)
    if len(t) <= n:
        return t
    return t[:n].rsplit(" ", 1)[0].rstrip(",;:—-") + "…"


TITLE = {"01": "Lincoln Memorial", "02": "Washington Monument", "03": "United States Capitol, the West Front",
 "04": "The White House from Lafayette Square", "05": "Jefferson Memorial", "06": "Martin Luther King Jr. Memorial",
 "07": "Vietnam Veterans Memorial", "08": "National Archives", "09": "Library of Congress",
 "10": "Supreme Court of the United States", "11": "Georgetown, M Street and the C&O Canal", "12": "Union Station",
 "13": "World War II Memorial", "14": "Korean War Veterans Memorial", "15": "Franklin D. Roosevelt Memorial",
 "16": "Tidal Basin and the Cherry Trees", "17": "Smithsonian Castle", "18": "Ford's Theatre and the Petersen House",
 "19": "Old Post Office and Clock Tower", "20": "Pennsylvania Avenue and Freedom Plaza", "21": "Chinatown Friendship Archway",
 "22": "Dupont Circle", "23": "Embassy Row", "24": "U Street and the Lincoln Theatre", "25": "African American Civil War Memorial",
 "26": "Eastern Market", "27": "United States Botanic Garden", "28": "Washington National Cathedral",
 "29": "The Wharf and the Maine Avenue Fish Market", "30": "Frederick Douglass House, Cedar Hill", "40": "Old Stone House"}
F = "Free to Visit"
# Architect tags (Job 5). Named in the tour's own script unless marked; see README.
ARCH = {
 "01": ["Henry Bacon"], "02": ["Robert Mills"], "04": ["James Hoban"], "05": ["John Russell Pope"],
 "07": ["Maya Lin"], "08": ["John Russell Pope"], "09": ["Smithmeyer & Pelz"], "10": ["Cass Gilbert"],
 "12": ["Daniel Burnham"], "13": ["Friedrich St. Florian"], "15": ["Lawrence Halprin"],
 "17": ["James Renwick Jr."], "19": ["Willoughby J. Edbrooke"], "21": ["Alfred Liu"], "22": ["Henry Bacon"],
 "24": ["John A. Lankford"], "26": ["Adolf Cluss"],
}

TAGS = {
 "01": ["Monument", "History", "Remembrance", "Neoclassical", "Iconic Landmark", F],
 "02": ["Monument", "Tower", "History", "Engineering", "Iconic Landmark", "Viewpoint", F],
 "03": ["Civic", "Notable Building", "Power", "History", "Neoclassical", "Iconic Landmark", F],
 "04": ["Civic", "Notable Building", "Power", "History", "Neoclassical", "Iconic Landmark", F],
 "05": ["Monument", "History", "Remembrance", "Neoclassical", "Iconic Landmark", F],
 "06": ["Monument", "History", "Remembrance", "Public Art", "Contemporary", "Iconic Landmark", F],
 "07": ["Monument", "War", "Remembrance", "History", "Modernist", "Iconic Landmark", F],
 "08": ["Civic", "Notable Building", "Museum", "History", "Power", "Neoclassical", F],
 "09": ["Library", "Notable Building", "Literature", "Architecture", "Beaux-Arts", "Iconic Landmark", F],
 "10": ["Civic", "Notable Building", "Power", "History", "Neoclassical", F],
 "11": ["District", "Waterfront", "History", "Engineering", "Commerce", F],
 "12": ["Notable Building", "Architecture", "Engineering", "Beaux-Arts", "Iconic Landmark", F],
 "13": ["Monument", "War", "Remembrance", "History", F],
 "14": ["Monument", "War", "Remembrance", "Public Art", F],
 "15": ["Monument", "History", "Power", "Remembrance", "Public Art", F],
 "16": ["Park", "Waterfront", "Engineering", "Green Escape", "Iconic Landmark", F],
 "17": ["Museum", "Notable Building", "Architecture", "Victorian", "History", F],
 "18": ["Venue", "Museum", "History", "Crime", "Remembrance"],
 "19": ["Tower", "Notable Building", "Architecture", "Victorian", "Viewpoint", "Power"],
 "20": ["Public Square", "Civic", "Power", "History", F],
 "21": ["Monument", "Immigration", "Public Art", F],
 "22": ["Park", "Public Square", "Public Art", "History", "Green Escape", F],
 "23": ["District", "Architecture", "Power", "Gilded Age", F],
 "24": ["District", "Venue", "Performance", "History", "After Dark"],
 "25": ["Monument", "War", "Remembrance", "History", "Public Art", F],
 "26": ["Market", "Food", "Commerce", "History", "Victorian"],
 "27": ["Park", "Architecture", "Green Escape", F],
 "28": ["Religious Building", "Faith", "Architecture", "Gothic", "Iconic Landmark", "Viewpoint"],
 "29": ["Waterfront", "Market", "Food", "Maritime", "Commerce", F],
 "30": ["Museum", "History", "Remembrance", "Viewpoint"],
 "40": ["Museum", "Notable Building", "History", "Colonial", "Hidden Gem", F],
}
WALKSLUG = {"W1": "washington-dc-long-room-walk", "W2": "washington-dc-around-the-water-walk",
            "W3": "washington-dc-older-than-the-city-walk", "W4": "washington-dc-the-avenue-walk",
            "W5": "washington-dc-city-that-isnt-a-state-walk"}
# walking distance as each walk's own intro states it (miles -> metres), not straight lines x 1.25:
# W1 "about one point three miles", W2 "about two miles", W3 "about one point two miles",
# W4 "about one point six miles", W5 "a little over two" (master list section 4)
DIST = {"W1": 2100, "W2": 3200, "W3": 1900, "W4": 2600, "W5": 3400}
# walk: (title, hero from (single num or stop key), category, tags, intro stop title)
WALK = {
 "W1": ("The Long Room — Lincoln Memorial to the Washington Monument", "01", "history",
        ["Monument", "History", "Remembrance", "War", "Iconic Landmark", F], "Lincoln Memorial, the steps"),
 "W2": ("Around the Water — the Tidal Basin", "16", "natureAndParks",
        ["Park", "Waterfront", "History", "Remembrance", "Green Escape", F], "Tidal Basin, the paddle-boat dock"),
 "W3": ("Older Than the City — Georgetown and the River", "W3-4", "history",
        ["District", "Waterfront", "History", "Commerce", "Colonial", F], "The foot of Key Bridge"),
 "W4": ("The Avenue — Lafayette Square to Chinatown", "20", "history",
        ["District", "History", "Power", "Civic", F], "Lafayette Square, H and Sixteenth"),
 "W5": ("The City That Isn't a State — Union Station to the Capitol", "03", "history",
        ["District", "History", "Power", "Civic", F], "Columbus Circle"),
}

# ---- images: refuse to run until every single and connective has one until every single and connective has one
man = json.load(open(D + "image-manifest.json"))
imgs = {}
for m in man:
    imgs.setdefault(m["num"], []).append(m["name"])
for k in imgs:
    imgs[k].sort(key=lambda n: (not n.endswith("_hero.webp"), int(re.search(r"_(\d+)\.webp$", n).group(1)) if re.search(r"_(\d+)\.webp$", n) else 0))
rows = [l.rstrip("\n").split("\t") for l in open(WD + "coordinates.tsv")]
conn = [r[0] for r in rows if r[6].startswith("new:")]
need = sorted(TITLE) + conn
missing = [n for n in need if n not in imgs]
STANDIN = "STAND-IN.webp"
if missing:
    if not a.dry_run:
        sys.exit(f"NOT READY — no image yet for: {', '.join(missing)}. The owner backfills these before launch.")
    print("dry run: standing in for", missing)
    for n in missing:
        imgs[n] = [STANDIN]

singles, new = {}, []
files = sorted(f for f in os.listdir(D) if re.match(r"washington_dc_\d\d_.*\.txt$", f) and not f.endswith("_TTS.txt"))
for line, f in zip(open(D + "coordinates.tsv"), files):
    n, slug, la, lo, r, cat, note = line.rstrip("\n").split("\t")
    assert f.startswith(f"washington_dc_{n}_"), (n, f)
    ps = body(D + f); txt = "\n\n".join(ps); si = standpoint(ps)
    cap = sentences(ps[si])[0] if si is not None else sentences(ps[0])[0]
    lp = [ps[0]] + ([ps[si + 1]] if si is not None and si + 1 < len(ps) else ([ps[1]] if len(ps) > 1 else []))
    if si == 0:
        lp = [ps[1]] if len(ps) > 1 else lp
    hero, gal = imgs[n][0], imgs[n][1:]
    du = DUR[f"{slug}.mp3"]
    stop = dict(id=U(f"atlas-stop:was:{slug}:1"), order=0, title=TITLE[n], caption=cap,
                latitude=float(la), longitude=float(lo), audioURL=B + f"audio/{slug}.mp3",
                audioDurationSeconds=du, triggerMode="geofenced", triggerRadiusMeters=int(r),
                imageURL=B + "images/" + hero, transcriptText=txt)
    t = dict(id=U(f"atlas-tour:was:{slug}"), createdAt=a.created or "2026-11-11", title=TITLE[n],
             shortDescription=cut(txt), longDescription=" ".join(lp), makerId=MAKER,
             heroImageURL=B + "images/" + hero, additionalImageURLs=[B + "images/" + g for g in gal],
             kind="single", stops=[stop], introAudioURL=None, totalDurationSeconds=du,
             walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
             city=CITY, country="United States", relatedTourIds=[], primaryCategory=cat,
             tags=TAGS[n] + ARCH.get(n, []), priceUSD=0)
    new.append(t); singles[n] = t
assert len(singles) == 31


def hav(p, q):
    R = 6371000; p1, p2 = math.radians(p[0]), math.radians(q[0]); dl = math.radians(q[1] - p[1]); dp = p2 - p1
    return 2 * R * math.asin(math.sqrt(math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2))


for w, (title, herofrom, cat, tags, intro) in WALK.items():
    stops = []; slug = None
    for k, label, la, lo, r, sc, note in [x for x in rows if x[0].startswith(w + "-")]:
        i = int(k.split("-")[1]); ps = body(WD + "scripts/" + sc); txt = "\n\n".join(ps)
        slug = WALKSLUG[w]
        m = re.search(r"reuses single (\d\d)", note)
        img = B + "images/" + imgs[k][0] if k in imgs else (singles[m.group(1)]["heroImageURL"] if m else None)
        stops.append(dict(id=U(f"atlas-stop:was:{slug}:{i}"), order=i, title=intro if i == 0 else label,
                          caption=sentences(ps[0])[0], latitude=float(la), longitude=float(lo),
                          audioURL=B + f"audio/{slug}_stop{i}.mp3", audioDurationSeconds=DUR[f"{slug}_stop{i}.mp3"],
                          triggerMode="geofenced", triggerRadiusMeters=int(r), imageURL=img, transcriptText=txt))
    hero = singles[herofrom]["heroImageURL"] if herofrom in singles else B + "images/" + imgs[herofrom][0]
    ims = [s["imageURL"] for s in stops if s["imageURL"]]
    assert hero in ims, (w, hero)
    gal = []
    for x in ims:
        if x != hero and x not in gal:
            gal.append(x)
    ip = body(WD + "scripts/" + [x for x in rows if x[0] == w + "-0"][0][5])
    dist = sum(hav((p["latitude"], p["longitude"]), (q["latitude"], q["longitude"])) for p, q in zip(stops, stops[1:]))
    t = dict(id=U(f"atlas-tour:was:{slug}"), createdAt=a.created or "2026-11-11", title=title,
             shortDescription=cut(ip[0]), longDescription="\n\n".join(ip[:2]), makerId=MAKER,
             heroImageURL=hero, additionalImageURLs=gal, kind="multiStop", stops=stops, introAudioURL=None,
             totalDurationSeconds=round(sum(s["audioDurationSeconds"] for s in stops), 1),
             walkingDistanceMeters=DIST[w],
             centroidLatitude=round(sum(s["latitude"] for s in stops) / len(stops), 6),
             centroidLongitude=round(sum(s["longitude"] for s in stops) / len(stops), 6),
             city=CITY, country="United States", relatedTourIds=[], primaryCategory=cat,
             tags=tags, priceUSD=0)
    new.append(t)
    print(w, title, len(stops), "stops", t["totalDurationSeconds"], "s", t["walkingDistanceMeters"], "m")

maker = dict(id=MAKER, displayName="Atlas Studio WAS", platform="dozent", handle="atlas.was", avatarURL=None,
             avatarEmoji="🇺🇸",
             bio="Atlas Studio's Washington bureau — audio tours of a capital planned on paper before there was a city "
                 "to put it in: a long room of memorials turned into a stage, a river port older than the plan, an avenue "
                 "cut to join two buildings, and a city of people who live here and cannot vote for who governs them.",
             websiteURL=None)
last = max(i for i, m in enumerate(d["makers"]) if m["displayName"].startswith("Atlas Studio"))
d["makers"].insert(last + 1, maker)
assert not {t["id"] for t in d["tours"]} & {t["id"] for t in new}
d["tours"].extend(new)
out = a.dry_run or P
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print(len(new), "tours written to", out, "; maker", MAKER)
for n in ["01", "07", "12", "28", "40"]:
    t = singles[n]; print(n, t["title"], "|", t["stops"][0]["caption"][:90], "|", t["shortDescription"][:70])
