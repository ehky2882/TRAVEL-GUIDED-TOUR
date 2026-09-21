#!/usr/bin/env python3
"""An entry sitting far from every OTHER entry in its own city.

WHY
---
🔴 This is the only check here that needs **no gazetteer**, which is the point.
`spine-match.py` can only speak about entries Wikidata knows, and **2,901 of
them it does not** — a bucket its own footer calls *unexamined, not clean*. Many
of those are not even place names: `@hereinnyc` and `@urbanistariel` title pins
*"The Million Dollar Corner"*, *"A Greek Goddess on Fifth Avenue"*. No name
lookup will ever reach them.

But the catalogue knows where its own cities are. An entry claiming to be in
London that sits 58 km from every other London entry is answerable from the file
alone — and that is exactly how **"Great Court, British Museum"** was caught,
sitting in a business park in **Great Notley, Essex**. Note the tell: *GREAT
Court* → *GREAT Notley*. A geocoder had matched the wrong word, and neither
Wikidata nor OSM had ever been asked.

🔴 IT IS A QUESTION, NEVER A VERDICT
------------------------------------
A city's famous sights are often genuinely far out, and this check cannot tell
them from errors. In the first run, of 79 flagged, the overwhelming majority were
correct: Cape Point (48 km from Cape Town), Kansai Airport (37 km from Osaka),
the whole of Lantau from Hong Kong (23-31 km), Heathrow, the Củ Chi tunnels.
**The threshold scales with each city's OWN spread** so that a sprawling city is
not flagged wholesale, and it still is not enough. Read the subject.

⚠️ AND A LARGE SPAN CAN MEAN TWO CITIES SHARE A NAME. The catalogue carries a
`San Juan` in the Philippines and seven in Puerto Rico, and a `Jericho` in both
the United States and the West Bank. `country` disambiguates them and the data is
CORRECT; it is the city *name* that collides. `--homonyms` reports those
separately rather than calling them outliers.
"""
import argparse
import collections
import importlib.util
import json
import math
import os
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

FLOOR_M = 3000.0      # never flag inside this, however tight the city
SPREAD_X = 8.0        # ...or inside this many times the city's own median spread
MIN_OTHERS = 4        # a city needs this many OTHER entries to have an opinion
HOMONYM_M = 500_000.0 # beyond this, one "city" is almost certainly two


def _load(name, filename):
    path = os.path.join(HERE, filename)
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


marker = _load("_place_candidates", "check-place-candidates.py").marker


def entries(catalog):
    return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])


def entry_marker(entry):
    found = marker(entry)
    if found is not None:
        return found
    stops = entry.get("stops") or []
    return (stops[0]["latitude"], stops[0]["longitude"]) if stops else None


def metres(a, b):
    """🔴 Longitude scaled by latitude, or every distance outside the tropics is
    overstated — and in Reykjavík by a factor of two."""
    dlat = (a[0] - b[0]) * 111_320.0
    dlon = (a[1] - b[1]) * 111_320.0 * math.cos(math.radians(a[0]))
    return math.hypot(dlat, dlon)


def city_points(catalog):
    out = collections.defaultdict(list)
    for entry in entries(catalog):
        at = entry_marker(entry)
        city = (entry.get("city") or "").strip()
        if at and city:
            out[city].append((entry, at))
    return out


def homonyms(catalog, span_m=HOMONYM_M):
    """One city NAME holding two places. Not an outlier — a naming collision."""
    out = []
    for city, members in city_points(catalog).items():
        if len(members) < 2:
            continue
        span = max(metres(a[1], b[1]) for a in members for b in members)
        if span < span_m:
            continue
        countries = collections.Counter(str(e.get("country")) for e, _ in members)
        out.append({"city": city, "span_m": span, "countries": dict(countries),
                    "members": members})
    return sorted(out, key=lambda r: -r["span_m"])


def outliers(catalog, floor_m=FLOOR_M, spread_x=SPREAD_X, min_others=MIN_OTHERS):
    """Distance from the MEDIAN of the city's OTHER entries, scaled by the city's
    own median spread.

    🔴 Three things here are load-bearing and each was chosen against a failure:
    the MEDIAN (a mean is dragged by the very outlier we are hunting), the SELF
    EXCLUSION (an entry must not vote on its own centre), and the PER-CITY SCALE
    (a flat threshold flags every sprawling city wholesale).
    """
    pts = city_points(catalog)
    # A city split across countries is a homonym, not one city — measuring a
    # centre across both would make every member of the smaller one an outlier.
    homonym_cities = {r["city"] for r in homonyms(catalog)}
    found, scored = [], 0
    for city, members in pts.items():
        if city in homonym_cities or len(members) <= min_others:
            continue
        for entry, at in members:
            others = [p for e, p in members if e["id"] != entry["id"]]
            if len(others) < min_others:
                continue
            centre = (statistics.median(p[0] for p in others),
                      statistics.median(p[1] for p in others))
            spread = statistics.median(metres(p, centre) for p in others)
            scored += 1
            gap = metres(at, centre)
            if spread > 0 and gap > max(floor_m, spread_x * spread):
                found.append({"entry": entry, "city": city, "gap_m": gap,
                              "spread_m": spread, "at": at})
    return sorted(found, key=lambda r: -r["gap_m"]), scored


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    def pin(pid, lat, lon, city="C", country="X"):
        return {"id": pid, "title": pid, "city": city, "country": country,
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}

    check("longitude is scaled by latitude",
          abs(metres((60.0, 0.0), (60.0, 1.0)) - 111_320.0 * math.cos(math.radians(60))) < 1.0)

    # A tight city with one far member.
    tight = {"tours": [], "linkPins": [pin(f"p{i}", 51.50 + i * 0.001, -0.12) for i in range(8)]
             + [pin("far", 51.86, 0.52)]}
    rows, scored = outliers(tight)
    check("🔴 the far member is flagged", [r["entry"]["id"] for r in rows] == ["far"])
    check("every member was scored, not just the flagged one", scored == 9)

    # 🔴 A MEAN would be dragged toward the outlier; a MEDIAN is not.
    check("the centre is not dragged by the outlier — the gap stays large",
          rows[0]["gap_m"] > 30_000)

    # A sprawling city must not be flagged wholesale.
    sprawl = {"tours": [], "linkPins": [pin(f"s{i}", 22.3 + i * 0.03, 114.0 + i * 0.03)
                                        for i in range(10)]}
    check("🔴 a sprawling city is not flagged wholesale", outliers(sprawl)[0] == [])

    check("a city with too few others is skipped",
          outliers({"tours": [], "linkPins": [pin("a", 1.0, 2.0), pin("b", 40.0, 5.0)]})[0] == [])
    check("an entry with no city is skipped",
          outliers({"tours": [], "linkPins": [pin(f"p{i}", 51.5, -0.12) for i in range(6)]
                    + [{"id": "n", "title": "n", "stops": [{"order": 0, "latitude": 9.0,
                                                            "longitude": 9.0}]}]})[0] == [])

    # Homonyms: one name, two countries, far apart.
    hom = {"tours": [], "linkPins": [pin("ph", 14.59, 121.03, city="San Juan", country="Philippines")]
           + [pin(f"pr{i}", 18.46 + i * 0.001, -66.11, city="San Juan", country="Puerto Rico")
              for i in range(7)]}
    h = homonyms(hom)
    check("🔴 one city name in two countries is reported as a homonym",
          [r["city"] for r in h] == ["San Juan"])
    check("the homonym names both countries",
          set(h[0]["countries"]) == {"Philippines", "Puerto Rico"})
    check("🔴 a homonym city is NOT also reported as an outlier — its centre is "
          "meaningless", outliers(hom)[0] == [])

    check("the floor is honoured: a small gap in a tight city is not flagged",
          outliers({"tours": [], "linkPins": [pin(f"t{i}", 51.50 + i * 0.0001, -0.12)
                                              for i in range(8)] + [pin("near", 51.505, -0.12)]},
                   floor_m=3000.0)[0] == [])
    check("lowering the floor exposes it",
          outliers({"tours": [], "linkPins": [pin(f"t{i}", 51.50 + i * 0.0001, -0.12)
                                              for i in range(8)] + [pin("near", 51.505, -0.12)]},
                   floor_m=10.0)[0] != [])
    check("an entry with no stops is skipped, not crashed on",
          outliers({"tours": [], "linkPins": [pin(f"p{i}", 51.5, -0.12) for i in range(6)]
                    + [{"id": "x", "title": "x", "city": "C", "stops": []}]})[0] == [])
    check("a stop numbered other than 0 is still read",
          entry_marker({"stops": [{"order": 5, "latitude": 1.0, "longitude": 2.0}]}) == (1.0, 2.0))

    # 🔴 TWO far members, at the same far point. A MEAN centre is dragged toward
    # the second one while the first is being scored, and BOTH then read as
    # normal — the failure is silence, not a wrong number.
    pair = {"tours": [], "linkPins": [pin(f"t{i}", 51.500 + i * 0.001, -0.12) for i in range(7)]
            + [pin("far1", 51.860, 0.52), pin("far2", 51.861, 0.52)]}
    check("🔴 two far members are BOTH flagged — a mean centre would hide them",
          sorted(r["entry"]["id"] for r in outliers(pair)[0]) == ["far1", "far2"])

    # 🔴 An entry must not vote on its own centre. With four out and four in, a
    # centre computed over ALL members lands midway and flags nothing.
    split = {"tours": [], "linkPins": [pin(f"i{i}", 51.500 + i * 0.001, -0.12) for i in range(4)]
             + [pin(f"o{i}", 51.860 + i * 0.001, 0.52) for i in range(4)]}
    check("🔴 an entry does not vote on its own centre",
          {r["entry"]["id"] for r in outliers(split)[0]} >= {"o0", "o1", "o2", "o3"})

    # A city of three has no opinion worth having.
    three = {"tours": [], "linkPins": [pin("a", 51.500, -0.12), pin("b", 51.501, -0.12),
                                       pin("c", 51.860, 0.52)]}
    check("a city of three entries says nothing", outliers(three)[0] == [])

    # 🔴 A tour and a pin are ONE population. The catalogue keeps them in two
    # arrays and the defect does not care which array it landed in.
    mixed = {"tours": [pin("tour-far", 51.860, 0.52)],
             "linkPins": [pin(f"p{i}", 51.500 + i * 0.001, -0.12) for i in range(8)]}
    check("🔴 a TOUR is scored too, not only a pin",
          [r["entry"]["id"] for r in outliers(mixed)[0]] == ["tour-far"])

    # The city name is read from the entry. If it were assumed, the entry above
    # with no city would be pulled into London and flagged.
    check("the city is read from the entry, not assumed",
          outliers({"tours": [], "linkPins": [pin(f"p{i}", 51.500 + i * 0.001, -0.12)
                                              for i in range(8)]
                    + [{"id": "n", "title": "n", "stops": [{"order": 0, "latitude": 9.0,
                                                            "longitude": 9.0}]}]})[0] == [])

    # 🔴 A city whose OTHER entries sit on one point has no scale of its own, so
    # it is held out rather than measured against a floor alone. Measured on the
    # live catalogue 2026-09-21, this withholds exactly TWO rows of 4,174 scored,
    # and both are noise: Denver holds five entries, THREE of them the same
    # building (Populus), so its median spread is 0 and two ordinary motels 3.3
    # and 5.8 km away would read as outliers.
    onepoint = {"tours": [], "linkPins": [pin(f"p{i}", 51.500, -0.12) for i in range(6)]
                + [pin("far", 51.860, 0.52)]}
    check("a city whose other entries are ONE point has no scale, so it flags nothing",
          outliers(onepoint)[0] == [])

    total = 21
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--limit", type=int, default=30)
    ap.add_argument("--homonyms", action="store_true",
                    help="report city names holding two different places, and stop")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)

        hom = homonyms(catalog)
        if a.homonyms:
            print(f"{len(hom)} city name(s) holding two different places\n")
            for row in hom:
                print(f"  {row['span_m']/1000:8.0f} km  {row['city'][:24]:24} {row['countries']}")
            print("\n⚠️ NOT errors — `country` disambiguates them and the data is correct. "
                  "But they\n   count as ONE city, and anything grouping by city name alone "
                  "will merge them.")
            return 1 if hom else 0

        rows, scored = outliers(catalog)
        print(f"{scored} entries scored against their own city "
              f"({len(hom)} homonym cities held out) · {len(rows)} flagged\n")
        for row in rows[:a.limit]:
            entry = row["entry"]
            print(f"  {row['gap_m']/1000:7.1f} km from {row['city'][:18]:18} "
                  f"(city spread {row['spread_m']/1000:5.1f} km)  "
                  f"{(entry.get('title') or '')[:36]}")
        if len(rows) > a.limit:
            print(f"  … and {len(rows) - a.limit} more (raise --limit)")
        if rows:
            print("\n⚠️  NOT a verdict. A city's famous sights are often genuinely far out "
                  "— Cape Point\n    is 48 km from Cape Town and correct. Read the subject "
                  "before the number. What is\n    worth acting on is an entry whose "
                  "SUBJECT has no reason to be out there.")
        return 1 if rows else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
