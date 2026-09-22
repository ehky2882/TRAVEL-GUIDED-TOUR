#!/usr/bin/env python3
"""The creator said where they were. Does the pin agree?

🔴 WHY THIS CAN EXIST NOW. Until 2026-09-21 the pipeline stored `caption[:140]`
and threw the rest away — and creators put their location LAST, so the cut
landed on it. Only 535 captions carried a location marker, which was a floor
rather than a count. Re-reading 2,351 posts took that to **914**, and this
check is what that recovery was for.

🔴 IT TESTS THE LOCALITY, NOT THE DISTANCE — deliberately, and the runbook
says why (rule 8d: *verify by ward, never by distance alone*). Two failures
this project already paid for:

* **Cube House, Toronto.** Geocoding the caption's own address put it 1,421 m
  from our pin. The pin was RIGHT — an OSM node of that name sits exactly on
  it. **An address-only geocode would have moved a correct pin.**
* **Sun Tower, Yantai.** 23.5 km from its only candidate, and distance could
  not settle it. What did: our point reverse-geocoded into 莱山区 while the
  owner's address said 福山區 — **the wrong district**, which proves the pin is
  wrong without yet claiming where it belongs.

So this asks one question: **the caption names a city we know; is it this
entry's city?** Nothing is geocoded, nothing external is consulted, and the
gazetteer is the catalogue's own list of cities — the same trick as
`check-city-outliers.py`.

⚠️ A QUESTION, NEVER A VERDICT. A caption may name a neighbouring town, a
metro area, or the city a creator travelled from. Read the entry before the
number.
"""
import argparse
import collections
import json
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

MARKER = "\U0001f4cd"

# 🔴 Cities that are the SAME place for this test. A pin in Brooklyn whose
# caption says "NYC" is not a finding, and the catalogue stores both as cities.
# Each frozenset is one metro whose members must never flag each other.
SAME_PLACE = [
    frozenset({"new york", "brooklyn", "queens", "bronx", "staten island",
               "manhattan", "nyc"}),
    frozenset({"hong kong", "kowloon"}),
    frozenset({"london", "city of london"}),
    frozenset({"washington", "washington dc", "dc"}),
]


def fold(text):
    """Accent- and case-insensitive. ⚠️ `São Paulo`/`Sao Paulo` and
    `Zurich`/`Zürich` were the same city spelled two ways in this catalogue and
    had to be merged, so folding is not optional here."""
    stripped = unicodedata.normalize("NFKD", text or "")
    return "".join(ch for ch in stripped if not unicodedata.combining(ch)).strip().lower()


def entries(catalog):
    return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])


def known_cities(catalog):
    """The gazetteer, taken from the catalogue itself.

    ⚠️ Only names of 4+ characters. Short ones ('Ica', 'Hue', 'Bar') appear
    inside ordinary words and turn every caption into a match."""
    out = {}
    for e in entries(catalog):
        city = (e.get("city") or "").strip()
        if len(fold(city)) >= 4:
            out.setdefault(fold(city), city)
    return out


def tail(caption):
    """What the creator wrote AFTER the last location marker.

    🔴 After the LAST one, not the first. A caption that opens with
    '📍Barker Road Station - Hong Kong Built in 1919...' puts prose after the
    marker; one that ends '...worth the trip 📍 Sunnyside, NY' puts the
    location there. Taking the last marker prefers the deliberate sign-off."""
    if MARKER not in (caption or ""):
        return ""
    return caption.split(MARKER)[-1]


def cities_named(text, gazetteer):
    """Every known city named in the text, matched on whole words only."""
    folded = fold(text)
    found = []
    for key, display in gazetteer.items():
        if re.search(r"(?<![a-z0-9])" + re.escape(key) + r"(?![a-z0-9])", folded):
            found.append(display)
    return sorted(set(found))


def compatible(a, b):
    """Two city names that must not be reported against each other."""
    fa, fb = fold(a), fold(b)
    if fa == fb:
        return True
    return any(fa in group and fb in group for group in SAME_PLACE)


def city_centres(catalog):
    """Where each city is, taken from the median of its own entries.

    ⚠️ MEDIAN, not mean — one outlying entry must not drag a city's centre,
    the same reason `check-city-outliers.py` gives."""
    import statistics
    pts = collections.defaultdict(list)
    for e in entries(catalog):
        stops = e.get("stops") or []
        city = (e.get("city") or "").strip()
        if not stops or not city:
            continue
        lat, lon = stops[0].get("latitude"), stops[0].get("longitude")
        if lat is None or lon is None:
            continue
        pts[fold(city)].append((lat, lon))
    return {k: (statistics.median(p[0] for p in v), statistics.median(p[1] for p in v))
            for k, v in pts.items()}


def metres(a, b):
    """Longitude scaled by latitude, or every distance outside the tropics is
    overstated."""
    import math
    dlat = (a[0] - b[0]) * 111_320.0
    dlon = (a[1] - b[1]) * 111_320.0 * math.cos(math.radians(a[0]))
    return math.hypot(dlat, dlon)


def far_apart(a, b, centres, floor_m=25_000.0):
    """🔴 Is the named city somewhere ELSE, or next door?

    Most of what this check surfaces is a neighbourhood or an adjacent town —
    Williamsburg inside Brooklyn, Kowloon City inside Hong Kong, Beacon Hill
    inside Boston, the Vatican inside Rome. Those are agreements written at a
    finer grain, not disagreements. A city the catalogue cannot place is
    treated as far, because an unplaceable name is exactly what a wrong city
    looks like."""
    ca, cb = centres.get(fold(a)), centres.get(fold(b))
    if ca is None or cb is None:
        return True
    return metres(ca, cb) > floor_m


def disagreements(catalog):
    """Entries whose caption tail names a city we know that is not theirs.

    Both halves matter: the caption must name a city **and** none of the cities
    it names may be the entry's own — a caption reading 'best in Brooklyn, far
    better than Chicago' still agrees with a Brooklyn pin.
    """
    gaz = known_cities(catalog)
    centres = city_centres(catalog)
    found, scored = [], 0
    for e in entries(catalog):
        stops = e.get("stops") or []
        city = (e.get("city") or "").strip()
        if not stops or not city:
            continue
        text = tail(stops[0].get("caption") or "")
        if not text:
            continue
        named = cities_named(text, gaz)
        if not named:
            continue
        scored += 1
        if any(compatible(city, n) for n in named):
            continue
        # ...and the named city must be somewhere ELSE, not a finer grain of here.
        # 🔴 ...and it must not be part of the venue's own NAME. "Venice
        # Leather", "Bistrot Lyon", "The Ice Bath Club", "Shanghai Street" all
        # carry a city word that says nothing about where they are. This is the
        # single largest false-positive class in the live catalogue.
        title = fold(e.get("title") or "")
        named = [n for n in named
                 if not re.search(r"(?<![a-z0-9])" + re.escape(fold(n)) + r"(?![a-z0-9])",
                                  title)]
        distant = [n for n in named if far_apart(city, n, centres)]
        if distant:
            found.append({"entry": e, "city": city, "named": distant})
    return found, scored


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    def pin(pid, city, caption):
        return {"id": pid, "title": pid, "city": city,
                "stops": [{"order": 0, "caption": caption}]}

    check("fold ignores accents and case", fold("Zürich") == fold("ZURICH"))
    check("🔴 the tail is taken after the LAST marker, so an opening marker "
          "followed by prose does not win",
          tail("📍Barker Road Station Built in 1919 📍 Hong Kong").strip() == "Hong Kong")
    check("no marker means no tail", tail("just a caption") == "")

    gaz = {"paris": "Paris", "brooklyn": "Brooklyn", "miami": "Miami"}
    check("a known city in the text is found", cities_named("great in Paris", gaz) == ["Paris"])
    check("🔴 a city name inside a longer word is NOT a match",
          cities_named("parisian bakery", gaz) == [])
    check("matching ignores case and accents", cities_named("PARIS", gaz) == ["Paris"])

    cat = {"tours": [], "linkPins": [
        pin("wrong", "Miami", "amazing 📍 Paris"),
        pin("right", "Paris", "amazing 📍 Paris"),
        pin("nomark", "Miami", "amazing in Paris"),
        pin("noname", "Miami", "amazing 📍 @somehandle"),
    ]}
    rows, scored = disagreements(cat)
    check("🔴 a caption naming another city is flagged",
          [r["entry"]["id"] for r in rows] == ["wrong"])
    check("a caption naming its own city is not flagged", "right" not in
          [r["entry"]["id"] for r in rows])
    check("🔴 a city named OUTSIDE the marker tail is ignored — the test is "
          "about the creator's sign-off, not the prose", "nomark" not in
          [r["entry"]["id"] for r in rows])
    check("a tail naming no known city is not scored", scored == 2)

    check("🔴 NYC boroughs never flag each other",
          disagreements({"tours": [], "linkPins": [
              pin("bk", "Brooklyn", "best slice 📍 New York"),
              pin("ny", "New York", "no marker")]})[0] == [])
    check("Hong Kong and Kowloon are one place",
          disagreements({"tours": [], "linkPins": [
              pin("hk", "Hong Kong", "dim sum 📍 Kowloon"),
              pin("kw", "Kowloon", "no marker")]})[0] == [])
    check("🔴 a tail naming BOTH its own city and another is not flagged",
          disagreements({"tours": [], "linkPins": [
              pin("two", "Miami", "better than 📍 Paris and Miami"),
              pin("pa", "Paris", "no marker")]})[0] == [])
    check("an entry with no city is skipped",
          disagreements({"tours": [], "linkPins": [
              {"id": "x", "stops": [{"caption": "📍 Paris"}]},
              pin("pa2", "Paris", "no marker")]})[0] == [])
    check("an entry with no stops is skipped, not crashed on",
          disagreements({"tours": [], "linkPins": [
              {"id": "y", "city": "Miami", "stops": []}]})[0] == [])
    # ⚠️ The second entry is not decoration. The gazetteer is built FROM the
    # catalogue, so "Paris" is only a known city because some entry is in it —
    # a caption naming a city the catalogue has never heard of is invisible to
    # this check by construction. That is the cost of using no external source.
    check("🔴 a tour is scored too, not only a pin",
          [r["entry"]["id"] for r in disagreements(
              {"tours": [pin("t", "Miami", "📍 Paris"), pin("p", "Paris", "no marker")],
               "linkPins": []})[0]] == ["t"])
    # 🔴 A neighbourhood is an agreement at a finer grain, not a disagreement.
    near = {"tours": [], "linkPins": [
        pin("a", "Brookfield", "📍 Nearton"), pin("b", "Nearton", "x")]}
    for e in near["linkPins"]:
        e["stops"][0]["latitude"], e["stops"][0]["longitude"] = 51.50, -0.12
    check("🔴 a named city that sits on top of this one is NOT a finding",
          disagreements(near)[0] == [])
    far = json.loads(json.dumps(near))
    far["linkPins"][1]["stops"][0]["latitude"] = 55.0
    check("🔴 the same name far away IS a finding",
          [r["entry"]["id"] for r in disagreements(far)[0]] == ["a"])
    check("🔴 a city word inside the entry's OWN TITLE is part of the venue name, "
          "not a location claim",
          disagreements({"tours": [], "linkPins": [
              dict(pin("v", "Hong Kong", "lovely shop 📍 Venice Leather"),
                   title="Venice Leather"),
              pin("ve", "Venice", "x")]})[0] == [])

    check("a city with no placeable entries is treated as far, not as agreeing",
          far_apart("Here", "Nowhere", {"here": (0.0, 0.0)}))

    check("⚠️ a city the catalogue does not know cannot be checked at all",
          disagreements({"tours": [], "linkPins": [
              pin("u", "Miami", "📍 Ulaanbaatar")]})[0] == [])
    check("⚠️ a SHORT city name is kept out of the gazetteer — it would match "
          "inside ordinary words",
          known_cities({"tours": [], "linkPins": [pin("s", "Hue", "x")]}) == {})

    total = 22
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--limit", type=int, default=40)
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        marked = sum(1 for e in entries(catalog)
                     for s in (e.get("stops") or [])[:1]
                     if MARKER in (s.get("caption") or ""))
        rows, scored = disagreements(catalog)
        print(f"{marked} captions carry a location marker · {scored} name a city "
              f"we know · {len(rows)} disagree with their pin\n")
        for r in sorted(rows, key=lambda r: r["city"])[:a.limit]:
            e = r["entry"]
            print(f"  pin says {r['city'][:16]:17} caption says "
                  f"{', '.join(r['named'])[:26]:27} {(e.get('title') or '')[:34]}")
        if len(rows) > a.limit:
            print(f"  … and {len(rows) - a.limit} more (raise --limit)")
        if rows:
            print("\n⚠️  NOT a verdict. A caption may name a neighbouring town, a metro "
                  "area, or\n    where the creator travelled from. Read the entry before "
                  "the number — and note\n    this says the CITY disagrees, never where "
                  "the pin should be instead.")
        return 1 if rows else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
