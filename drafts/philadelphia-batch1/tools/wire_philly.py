#!/usr/bin/env python3
"""Wire Philadelphia (Atlas Studio PHL) into Tours.json: 30 singles + 5 walks.

Adapted from drafts/boston-batch1/tools/wire_city.py. Differences:
  * durations come from audio-manifest.json (the MP3s live on gh-pages, not on disk);
  * images come from image-manifest.json, and the script REFUSES to run until every
    single and every walk connective has an image (owner, 2026-10-06: "dont launch
    the tours until i've backfilled everything");
  * --dry-run writes to a scratch path and fills any missing image with a stand-in
    URL, so the rest of the wiring can be validated before the photos arrive.

Usage (from the repo root):
  python3 drafts/philadelphia-batch1/tools/wire_philly.py --created 2026-10-DD
  python3 drafts/philadelphia-batch1/tools/wire_philly.py --dry-run /tmp/x/Tours.json

Image manifest rows: {"num": "05" or "W1-3", "name": "<file>.webp", ...}. A single's
hero is <slug>_hero.webp and its gallery <slug>_2.webp, _3 ...; a connective's image is
<walk-slug>_stop<N>.webp. Walk stops that revisit a single use that single's CURRENT hero.
"""
import argparse, json, math, os, re, sys, uuid

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
P = f"{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json"
B = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/"
D = f"{ROOT}/drafts/philadelphia-batch1/"
WD = f"{ROOT}/drafts/philadelphia-walks/"
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U("atlas-maker:phl")

ap = argparse.ArgumentParser()
ap.add_argument("--created", help="createdAt for every tour (launch date, YYYY-MM-DD)")
ap.add_argument("--dry-run", metavar="OUT", help="write to OUT and stand in for missing images")
a = ap.parse_args()
if not a.dry_run and not a.created:
    sys.exit("--created YYYY-MM-DD is required for a real run")

d = json.load(open(P))
assert not any(m["id"] == MAKER for m in d["makers"]), "Atlas Studio PHL is already in the catalogue"
DUR = {k: v["seconds"] for k, v in json.load(open(D + "audio-manifest.json")).items()}


def body(f):
    t = open(f, encoding="utf-8").read().split("\n---\n", 1)[1]
    ps = [p.strip() for p in re.split(r"\n\s*\n", t) if p.strip() and p.strip() != "*[beat]*"]
    return [re.sub(r"\n?\*\[beat\]\*\n?", "\n", p).strip() for p in ps]


def sentences(p):
    return re.findall(r".+?[.!?](?=\s|$)", p) or [p]


def standpoint(ps):
    for i, p in enumerate(ps):
        if re.match(r"(You should be|You're|You are)\b", p):
            return i
    return None


def cut(t, n=145):
    t = re.sub(r"\s+", " ", t)
    if len(t) <= n:
        return t
    return t[:n].rsplit(" ", 1)[0].rstrip(",;:—-") + "…"


TITLE = {"01": "Independence Hall", "02": "The Liberty Bell", "03": "The President's House",
 "04": "Elfreth's Alley", "05": "Christ Church", "06": "City Hall and William Penn",
 "07": "Philadelphia Museum of Art Steps and Eakins Oval", "08": "Reading Terminal Market",
 "09": "Rittenhouse Square", "10": "Franklin Court", "11": "Logan Square", "12": "Washington Square",
 "13": "Carpenters' Hall", "14": "Betsy Ross House", "15": "Congress Hall",
 "16": "Second Bank of the United States", "17": "Mother Bethel AME Church",
 "18": "Head House Square and the Shambles", "19": "Penn's Landing and the Delaware",
 "20": "Race Street Pier and the Ben Franklin Bridge", "21": "Eastern State Penitentiary",
 "22": "Fairmount Water Works", "23": "Boathouse Row", "24": "Rodin Museum",
 "25": "Masonic Temple and North Broad", "26": "Chinatown Friendship Gate", "27": "Franklin Square",
 "28": "Christ Church Burial Ground and Arch Street Meeting House", "29": "LOVE Park and Dilworth Park",
 "30": "One Liberty Place and the Skyline"}
F = "Free to Visit"
TAGS = {
 "01": ["Notable Building", "Civic", "History", "Power", "Colonial", "Iconic Landmark", F],
 "02": ["Monument", "Museum", "History", "Remembrance", "Iconic Landmark", F],
 "03": ["Monument", "History", "Power", "Remembrance", F],
 "04": ["District", "Architecture", "History", "Colonial", "Hidden Gem", F],
 "05": ["Religious Building", "Faith", "History", "Colonial", "Iconic Landmark"],
 "06": ["Civic", "Notable Building", "Power", "Architecture", "Victorian", "Iconic Landmark", F],
 "07": ["Museum", "Art", "Architecture", "Neoclassical", "Iconic Landmark", "Viewpoint", F],
 "08": ["Market", "Food", "Commerce", "History", "Iconic Landmark", F],
 "09": ["Park", "Public Square", "History", "Green Escape", F],
 "10": ["Museum", "History", "Architecture", F],
 "11": ["Public Square", "Park", "Public Art", "Art", F],
 "12": ["Park", "Public Square", "Monument", "Remembrance", "History", "War", F],
 "13": ["Notable Building", "Museum", "History", "Colonial", F],
 "14": ["Museum", "Notable Building", "History", "Colonial"],
 "15": ["Notable Building", "Civic", "History", "Power", "Colonial", F],
 "16": ["Notable Building", "Museum", "Architecture", "Commerce", "Power", "Neoclassical", F],
 "17": ["Religious Building", "Faith", "History", "Remembrance"],
 "18": ["Market", "Public Square", "Commerce", "History", "Colonial", F],
 "19": ["Waterfront", "Maritime", "History", F],
 "20": ["Waterfront", "Bridge", "Engineering", "Viewpoint", "Green Escape", F],
 "21": ["Museum", "Notable Building", "Crime", "History", "Gothic"],
 "22": ["Waterfront", "Engineering", "Architecture", "History", "Neoclassical", F],
 "23": ["Waterfront", "Architecture", "Victorian", "History", "After Dark", F],
 "24": ["Museum", "Art", "Architecture", "Beaux-Arts", "Public Art"],
 "25": ["Notable Building", "Architecture", "History", "Victorian"],
 "26": ["Monument", "Immigration", "Public Art", F],
 "27": ["Park", "Public Square", "History", "Green Escape", F],
 "28": ["Religious Building", "Remembrance", "Faith", "History", "Colonial"],
 "29": ["Public Square", "Park", "Public Art", "Art", "Iconic Landmark", F],
 "30": ["Notable Building", "Architecture", "Viewpoint", "Iconic Landmark", F],
}
# walk: (title, single whose hero leads, category, tags, intro stop title)
WALK = {
 "W1": ("The Fifth Square — Washington Square to Penn's Landing", "12", "culturalHeritage",
        ["District", "History", "Faith", "Remembrance", F], "Washington Square, by the Tomb"),
 "W2": ("Broad and Market — Franklin Square to Rittenhouse Square", "06", "architecture",
        ["Architecture", "History", "Civic", F], "Franklin Square"),
 "W3": ("The Boulevard — Logan Circle to Boathouse Row", "07", "architecture",
        ["District", "Architecture", "History", "Art", "Beaux-Arts", F], "Logan Circle"),
 "W4": ("Brick — Christ Church to Race Street Pier", "04", "history",
        ["District", "History", "Architecture", "Colonial", "Faith", F], "Christ Church, the gate on Second Street"),
 "W5": ("The House That Isn't There — Carpenters' Hall to the President's House", "03", "history",
        ["District", "History", "Power", "Remembrance", "Colonial", F], "Carpenters' Hall, the court off Chestnut Street"),
}

# ---- images: refuse to run until every single and connective has one
man = json.load(open(D + "image-manifest.json"))
imgs = {}
for m in man:
    imgs.setdefault(m["num"], []).append(m["name"])
for k in imgs:
    imgs[k].sort(key=lambda n: (not n.endswith("_hero.webp"), int(re.search(r"_(\d+)\.webp$", n).group(1)) if re.search(r"_(\d+)\.webp$", n) else 0))
rows = [l.rstrip("\n").split("\t") for l in open(WD + "coordinates.tsv")]
conn = [r[0] for r in rows if r[6].startswith("new:")]
need = [f"{i:02d}" for i in range(1, 31)] + conn
missing = [n for n in need if n not in imgs]
STANDIN = "STAND-IN.webp"
if missing:
    if not a.dry_run:
        sys.exit(f"NOT READY — no image yet for: {', '.join(missing)}. The owner backfills these before launch.")
    print("dry run: standing in for", missing)
    for n in missing:
        imgs[n] = [STANDIN]

singles, new = {}, []
files = sorted(f for f in os.listdir(D) if re.match(r"philadelphia_\d\d_.*\.txt$", f) and not f.endswith("_TTS.txt"))
for line, f in zip(open(D + "coordinates.tsv"), files):
    n, slug, la, lo, r, cat, note = line.rstrip("\n").split("\t")
    assert f.startswith(f"philadelphia_{n}_"), (n, f)
    ps = body(D + f); txt = "\n\n".join(ps); si = standpoint(ps)
    cap = sentences(ps[si])[0] if si is not None else sentences(ps[0])[0]
    lp = [ps[0]] + ([ps[si + 1]] if si is not None and si + 1 < len(ps) else ([ps[1]] if len(ps) > 1 else []))
    if si == 0:
        lp = [ps[1]] if len(ps) > 1 else lp
    hero, gal = imgs[n][0], imgs[n][1:]
    du = DUR[f"{slug}.mp3"]
    stop = dict(id=U(f"atlas-stop:phl:{slug}:1"), order=0, title=TITLE[n], caption=cap,
                latitude=float(la), longitude=float(lo), audioURL=B + f"audio/{slug}.mp3",
                audioDurationSeconds=du, triggerMode="geofenced", triggerRadiusMeters=int(r),
                imageURL=B + "images/" + hero, transcriptText=txt)
    t = dict(id=U(f"atlas-tour:phl:{slug}"), createdAt=a.created or "2026-10-06", title=TITLE[n],
             shortDescription=cut(txt), longDescription=" ".join(lp), makerId=MAKER,
             heroImageURL=B + "images/" + hero, additionalImageURLs=[B + "images/" + g for g in gal],
             kind="single", stops=[stop], introAudioURL=None, totalDurationSeconds=du,
             walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
             city="Philadelphia", country="United States", relatedTourIds=[], primaryCategory=cat,
             tags=TAGS[n], priceUSD=0)
    new.append(t); singles[n] = t
assert len(singles) == 30


def hav(p, q):
    R = 6371000; p1, p2 = math.radians(p[0]), math.radians(q[0]); dl = math.radians(q[1] - p[1]); dp = p2 - p1
    return 2 * R * math.asin(math.sqrt(math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2))


for w, (title, herofrom, cat, tags, intro) in WALK.items():
    stops = []; slug = None
    for k, label, la, lo, r, sc, note in [x for x in rows if x[0].startswith(w + "-")]:
        i = int(k.split("-")[1]); ps = body(WD + "scripts/" + sc); txt = "\n\n".join(ps)
        slug = re.match(r"(.+?)_multistop_", sc).group(1).replace("_", "-")
        m = re.search(r"reuses single (\d\d)", note)
        img = None if i == 0 else (singles[m.group(1)]["heroImageURL"] if m else B + "images/" + imgs[k][0])
        stops.append(dict(id=U(f"atlas-stop:phl:{slug}:{i}"), order=i, title=intro if i == 0 else label,
                          caption=sentences(ps[0])[0], latitude=float(la), longitude=float(lo),
                          audioURL=B + f"audio/{slug}_stop{i}.mp3", audioDurationSeconds=DUR[f"{slug}_stop{i}.mp3"],
                          triggerMode="geofenced", triggerRadiusMeters=int(r), imageURL=img, transcriptText=txt))
    hero = singles[herofrom]["heroImageURL"]
    ims = [s["imageURL"] for s in stops if s["imageURL"]]
    assert hero in ims, (w, hero)
    gal = []
    for x in ims:
        if x != hero and x not in gal:
            gal.append(x)
    ip = body(WD + "scripts/" + [x for x in rows if x[0] == w + "-0"][0][5])
    dist = sum(hav((p["latitude"], p["longitude"]), (q["latitude"], q["longitude"])) for p, q in zip(stops, stops[1:]))
    t = dict(id=U(f"atlas-tour:phl:{slug}"), createdAt=a.created or "2026-10-06", title=title,
             shortDescription=cut(ip[0]), longDescription="\n\n".join(ip[:2]), makerId=MAKER,
             heroImageURL=hero, additionalImageURLs=gal, kind="multiStop", stops=stops, introAudioURL=None,
             totalDurationSeconds=sum(s["audioDurationSeconds"] for s in stops),
             walkingDistanceMeters=int(round(dist * 1.25 / 100) * 100),
             centroidLatitude=round(sum(s["latitude"] for s in stops) / len(stops), 6),
             centroidLongitude=round(sum(s["longitude"] for s in stops) / len(stops), 6),
             city="Philadelphia", country="United States", relatedTourIds=[], primaryCategory=cat,
             tags=tags, priceUSD=0)
    new.append(t)
    print(w, title, len(stops), "stops", t["totalDurationSeconds"], "s", t["walkingDistanceMeters"], "m")

maker = dict(id=MAKER, displayName="Atlas Studio PHL", platform="dozent", handle="atlas.phl", avatarURL=None,
             avatarEmoji="🇺🇸",
             bio="Atlas Studio's Philadelphia bureau — audio tours of a city drawn before it was built: five squares "
                 "laid out on paper in 1682, a statehouse dressed up afterwards to match its fame, a president's house "
                 "that is now an outline, and a boulevard cut through the grid to reach a museum on a hill.",
             websiteURL=None)
last = max(i for i, m in enumerate(d["makers"]) if m["displayName"].startswith("Atlas Studio"))
d["makers"].insert(last + 1, maker)
assert not {t["id"] for t in d["tours"]} & {t["id"] for t in new}
d["tours"].extend(new)
out = a.dry_run or P
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print(len(new), "tours written to", out, "; maker", MAKER)
for n in ["01", "07", "12", "28"]:
    t = singles[n]; print(n, t["title"], "|", t["stops"][0]["caption"][:90], "|", t["shortDescription"][:70])
