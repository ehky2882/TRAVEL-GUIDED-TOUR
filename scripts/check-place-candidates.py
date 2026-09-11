#!/usr/bin/env python3
"""Find sites that several tours or pins already sit on but that have no place page.

WHY THIS EXISTS
---------------
On 2026-08-27 a batch of nineteen San Francisco link pins shipped with three
place candidates in it and nobody asked the owner. The evidence was in hand at
the time — two pins on an exactly identical coordinate, and two hero-slug
collisions against existing Atlas tours of the same subject — and it was read
only as a map-rendering and filename concern. The owner spotted the gap on a
glance at the map instead.

Nothing here is clever. The point is that it runs every time rather than
depending on a session noticing.

WHAT IT REPORTS, AND WHY THE TWO TIERS ARE DIFFERENT
----------------------------------------------------
1. **EXACT** — two or more markers on an identical coordinate with no place.
   This is the catalogue's documented identity rule (session 95: grouping
   anything within 40 m was measured and produced 43 places of which 19 were
   wrong, merging LACMA with the Academy Museum among others). Exact matches
   are provably one site and need no editorial judgement, so this tier exits
   non-zero: it is a thing to act on.

2. **TIGHT** — markers within `--tight` metres of each other, WHATEVER their
   titles say. Added 2026-09-11, because the subject-containment rule below is
   structurally blind to the commonest case in the catalogue: one site that two
   entries call by two unrelated names. "Hook & Ladder 8" and "The Ghostbusters
   Firehouse" are one firehouse 4 m apart and share not a single word; so are
   "Britain's Oldest Door" and "The Tomb of Elizabeth I", which are both
   Westminster Abbey, and "Chelsea Market" and a pin about Oreos, which are the
   same Nabisco building. None of them could ever reach the NEAR tier.
   🔴 Proximity is evidence, not proof, so this tier is for a human and does not
   affect the exit code. Two real false positives to expect: neighbouring but
   genuinely separate venues in a dense block (Hong Kong's food pins sit 10–20 m
   apart and are different restaurants), and coordinates rounded to 4 decimal
   places, which lands El Retiro 8 m from the Puerta de Alcalá.

3. **NEAR** — same-subject titles within `--radius` that are neither coincident
   nor already caught by TIGHT.
   🔴 These must NEVER be auto-created. A place needs its own copy, address and
   photograph, and picking the coordinate is a real decision — Grace Cathedral's
   tour sits on the Great Stairs while its pin sat on the OSM building node,
   71 m apart, and neither was wrong. Reported for a human, exit code unaffected.

⚠️ A NEAR pair is not automatically a defect. Tibidabo and Tibidabo Amusement
Park are 48 m apart and were deliberately left separate in #541 — a mountain
and a funfair are two subjects. Read them; do not batch-approve them.
"""

import argparse
import json
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402  (stamps every run; see scripts/runstamp.py)

DEFAULT_RADIUS_M = 500.0

# The TIGHT tier's radius. 25 m is the distance at which two markers in the
# real catalogue are nearly always one building: measured over all 3,269
# markers it yields 99 groups, of which the ones that are NOT a single site are
# a readable handful (dense restaurant blocks, and pairs whose coordinates are
# rounded to 4 dp). Widening it to 40 m is what session 95 measured and
# rejected for AUTO-CREATION — but this tier does not auto-create anything, so
# the trade is different here: the cost of a loose match is one line a human
# reads and dismisses.
DEFAULT_TIGHT_M = 25.0

# Words that carry no subject meaning, so "Chinatown" and "Chinatown Dragon
# Gate" still compare as related while "The Jordaan" and "The Jordaan" match
# exactly. City names are dropped because a title often repeats its own city.
STOPWORDS = {"the", "a", "an", "of", "at", "and", "in", "on", "to"}

# 🔴 THE FALSE-POSITIVE GUARD, AND IT IS NOT OPTIONAL.
# Dropping the city name from a title can reduce it to a single generic noun:
# "The Tower of London" in London becomes {"tower"}, which is then a subset of
# "Tower Bridge" and matches. Run against the real catalogue this produced
# three junk pairs on its first outing — Tower of London/Tower Bridge, New
# Museum/Tenement Museum, and Tokyo National Museum/National Museum of Western
# Art. A pair only counts when the SMALLER title carries at least one word that
# names something in particular, not just what kind of thing it is.
GENERIC = {
    "museum", "tower", "bridge", "square", "park", "cathedral", "church",
    "gate", "market", "library", "station", "gallery", "house", "hall",
    "centre", "center", "national", "city", "old", "new", "great", "royal",
    "grand", "public", "memorial", "garden", "gardens", "street", "building",
}


def marker(tour):
    """The coordinate the map actually draws: the stop at order 0.

    ⚠️ NOT the centroid. A walk's centroid is the mean of stops a kilometre
    apart — Montreal's Downtown walk sits 197 m from any of its own stops — so
    grouping on it would invent sites that are not anywhere.
    """
    for stop in tour.get("stops", []):
        if stop.get("order") == 0:
            return (stop["latitude"], stop["longitude"])
    return None


def haversine(a, b):
    radius = 6371000.0
    lat1, lat2 = math.radians(a[0]), math.radians(b[0])
    dlat = lat2 - lat1
    dlon = math.radians(b[1] - a[1])
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * radius * math.asin(math.sqrt(h))


def subject_words(title, city=None):
    text = re.sub(r"[^a-z0-9 ]", " ", (title or "").lower())
    drop = set(STOPWORDS)
    if city:
        drop |= {w for w in re.sub(r"[^a-z0-9 ]", " ", city.lower()).split() if w}
    return {w for w in text.split() if w and w not in drop}


def same_subject(a, b):
    """One title's meaningful words contain the other's.

    Deliberately narrower than a similarity score: session 95 found 398 marker
    pairs within 200 m catalogue-wide, so distance alone is useless and a fuzzy
    threshold would drown the signal. Containment left exactly two pairs.
    """
    wa = subject_words(a.get("title"), a.get("city"))
    wb = subject_words(b.get("title"), b.get("city"))
    if not wa or not wb:
        return False
    if not (wa <= wb or wb <= wa):
        return False
    smaller = wa if wa <= wb else wb
    return bool(smaller - GENERIC)


def entries(doc):
    out = [("tour", t) for t in doc.get("tours", [])]
    out += [("pin", t) for t in (doc.get("linkPins") or [])]
    return [(kind, t) for kind, t in out if marker(t)]


def scan(doc, radius_m=DEFAULT_RADIUS_M, tight_m=DEFAULT_TIGHT_M):
    claimed = {tid for p in (doc.get("places") or []) for tid in p.get("tourIds", [])}
    items = entries(doc)

    groups = {}
    for kind, t in items:
        groups.setdefault(marker(t), []).append((kind, t))
    exact = [
        (coord, members)
        for coord, members in groups.items()
        if len(members) >= 2 and not all(t["id"] in claimed for _, t in members)
    ]

    # ⚠️ Do NOT bucket these pairs by `city`. Two markers 20 m apart can carry
    # different city strings — the catalogue labels one side of a street
    # "New York" and the other "Brooklyn" — and a place spans that label. Bucket
    # on the geography instead: a grid of `radius_m`-sized cells, comparing each
    # marker only against its own cell and the eight around it, which cannot
    # miss a pair inside the radius and turns 5.3 million haversines into a few
    # thousand.
    cell = radius_m / 111_320.0               # degrees of latitude per cell
    grid = {}
    for kind, t in items:
        lat, lon = marker(t)
        grid.setdefault((int(lat // cell), int(lon // cell)), []).append((kind, t))

    tight, near, seen = [], [], set()
    for (gy, gx), bucket in grid.items():
        neighbours = [
            it
            for dy in (-1, 0, 1) for dx in (-1, 0, 1)
            for it in grid.get((gy + dy, gx + dx), ())
        ]
        for k1, a in bucket:
            for k2, b in neighbours:
                if a["id"] >= b["id"]:        # each unordered pair exactly once
                    continue
                key = (a["id"], b["id"])
                if key in seen:
                    continue
                dist = haversine(marker(a), marker(b))
                if dist == 0 or dist > radius_m:
                    continue                  # 0 is the EXACT tier's business
                if a["id"] in claimed and b["id"] in claimed:
                    continue
                seen.add(key)
                if dist <= tight_m:
                    tight.append((dist, (k1, a), (k2, b)))
                elif same_subject(a, b):
                    near.append((dist, (k1, a), (k2, b)))
    tight.sort(key=lambda r: r[0])
    near.sort(key=lambda r: r[0])
    return exact, tight, near


def report(doc, radius_m=DEFAULT_RADIUS_M, tight_m=DEFAULT_TIGHT_M, out=None):
    # ⚠️ `out=sys.stdout` as a DEFAULT binds the stream at import time, so it
    # keeps writing to the real stdout even after `--out` has teed it — the
    # report would then be missing from its own report file. Resolve it here.
    out = sys.stdout if out is None else out
    exact, tight, near = scan(doc, radius_m, tight_m)

    if exact:
        out.write(f"\nEXACT — {len(exact)} coincident group(s) with no place page.\n")
        out.write("  These meet the catalogue's own identity rule. Put them to the owner.\n")
        for coord, members in exact:
            out.write(f"\n  {coord[0]}, {coord[1]}\n")
            for kind, t in members:
                out.write(f"     [{kind:<4}] {t['title'][:56]:<57} {t.get('city')}\n")
    else:
        out.write("\nEXACT — none. Every coincident group is already a place.\n")

    if tight:
        out.write(f"\nTIGHT — {len(tight)} pair(s) within {tight_m:.0f} m, regardless of title.\n")
        out.write("  Proximity is evidence, not proof. Read each one; a dense block of\n"
                  "  restaurants and a coordinate rounded to 4 dp both land here.\n")
        for dist, (k1, a), (k2, b) in tight:
            out.write(f"  {dist:7.1f}m  [{k1}] {a['title'][:34]:<35} | "
                      f"[{k2}] {b['title'][:34]:<35} {a.get('city')}\n")
    else:
        out.write(f"\nTIGHT — none within {tight_m:.0f} m.\n")

    if near:
        out.write(f"\nNEAR — {len(near)} same-subject pair(s) {tight_m:.0f}–{radius_m:.0f} m apart.\n")
        out.write("  🔴 Never auto-create these. Read each one; some are deliberately separate.\n")
        for dist, (k1, a), (k2, b) in near:
            out.write(f"  {dist:7.0f}m  [{k1}] {a['title'][:34]:<35} | "
                      f"[{k2}] {b['title'][:34]:<35} {a.get('city')}\n")
    else:
        out.write(f"\nNEAR — none within {radius_m:.0f} m.\n")

    out.write(f"\n{len(exact)} exact, {len(tight)} tight, {len(near)} near.\n")
    return 1 if exact else 0


def selftest():
    """Offline. A checker nobody has shown a fault to is not evidence."""
    fails, ran = [], []

    def check(name, got, want):
        ran.append(name)
        if got != want:
            fails.append(f"{name}: got {got!r}, want {want!r}")

    def t(tid, title, lat, lon, city="Testville", order=0):
        return {"id": tid, "title": title, "city": city,
                "stops": [{"order": order, "latitude": lat, "longitude": lon}]}

    # --- marker: order 0 only, never the centroid
    check("marker reads stop 0", marker(t("a", "X", 1.0, 2.0)), (1.0, 2.0))
    walk = {"id": "w", "title": "W", "stops": [{"order": 1, "latitude": 9.0, "longitude": 9.0},
                                               {"order": 0, "latitude": 1.0, "longitude": 2.0}]}
    check("marker ignores later stops", marker(walk), (1.0, 2.0))
    check("marker is None with no stop 0",
          marker({"id": "z", "title": "Z", "stops": [{"order": 1, "latitude": 0, "longitude": 0}]}), None)

    # --- exact tier
    doc = {"tours": [t("1", "Foo", 10.0, 20.0), t("2", "Foo Museum", 10.0, 20.0)], "linkPins": [], "places": []}
    exact, tight, near = scan(doc)
    check("coincident pair is EXACT", len(exact), 1)
    check("coincident pair is not also NEAR", len(near), 0)

    doc["places"] = [{"id": "p", "name": "Foo", "tourIds": ["1", "2"]}]
    check("an existing place silences it", len(scan(doc)[0]), 0)

    # A place that covers only ONE of the two must still report: the other
    # member is the thing that would go missing from the page.
    doc["places"] = [{"id": "p", "name": "Foo", "tourIds": ["1"]}]
    check("partially-claimed group still reports", len(scan(doc)[0]), 1)

    # --- near tier
    doc2 = {"tours": [t("1", "Grace Cathedral", 37.7919, -122.4127),
                      t("2", "Grace Cathedral", 37.79182, -122.41349)],
            "linkPins": [], "places": []}
    e2, g2, n2 = scan(doc2)
    check("same subject nearby is NEAR", len(n2), 1)
    check("same subject nearby is not EXACT", len(e2), 0)
    check("71 m is beyond TIGHT, so NEAR is the only tier that sees it", len(g2), 0)
    check("distance is roughly right", 60 < n2[0][0] < 80, True)

    # Different subjects at the same distance must NOT be reported.
    doc3 = {"tours": [t("1", "Portsmouth Square", 37.7919, -122.4127),
                      t("2", "Waverly Place", 37.79182, -122.41349)],
            "linkPins": [], "places": []}
    check("different subjects nearby are ignored", len(scan(doc3)[2]), 0)

    # Beyond the radius, even the same subject is out of scope.
    doc4 = {"tours": [t("1", "Chinatown", 37.7919, -122.4127),
                      t("2", "Chinatown", 37.8100, -122.4127)],
            "linkPins": [], "places": []}
    check("beyond the radius is ignored", len(scan(doc4, radius_m=500)[2]), 0)

    # --- subject matching
    check("city name is not subject", subject_words("Chinatown", "San Francisco"), {"chinatown"})
    check("stopwords dropped", subject_words("The Legion of Honor"), {"legion", "honor"})
    check("containment matches",
          same_subject({"title": "Chinatown"}, {"title": "Chinatown Dragon Gate"}), True)
    check("disjoint titles do not match",
          same_subject({"title": "Portsmouth Square"}, {"title": "Waverly Place"}), False)
    # 🔴 The look-alike guard: a shared generic word must not be enough.
    check("a shared generic word is not a subject match",
          same_subject({"title": "Union Square"}, {"title": "Portsmouth Square"}), False)
    check("empty title never matches", same_subject({"title": ""}, {"title": "Foo"}), False)

    # 🔴 The three junk pairs the real catalogue produced on the first run. Each
    # matched only because stripping the city left a bare generic noun behind.
    check("Tower of London is not Tower Bridge",
          same_subject({"title": "The Tower of London", "city": "London"},
                       {"title": "Tower Bridge", "city": "London"}), False)
    check("New Museum is not the Tenement Museum",
          same_subject({"title": "New Museum", "city": "New York"},
                       {"title": "Tenement Museum", "city": "New York"}), False)
    check("Tokyo National Museum is not the National Museum of Western Art",
          same_subject({"title": "Tokyo National Museum", "city": "Tokyo"},
                       {"title": "The National Museum of Western Art", "city": "Tokyo"}), False)
    # ...while a one-word PROPER name must still match, which is what the
    # guard has to leave alone.
    check("a one-word proper name still matches",
          same_subject({"title": "The Jordaan", "city": "Amsterdam"},
                       {"title": "The Jordaan", "city": "Amsterdam"}), True)
    check("Tibidabo still matches its amusement park",
          same_subject({"title": "Tibidabo", "city": "Barcelona"},
                       {"title": "Tibidabo Amusement Park", "city": "Barcelona"}), True)

    # --- TIGHT tier: the case the subject rule is structurally blind to.
    # 🔴 Hook & Ladder 8 and the Ghostbusters Firehouse are one building 4 m
    # apart sharing not one word. NEAR can never see this pair; that is the
    # whole reason the tier exists.
    doc6 = {"tours": [], "places": [],
            "linkPins": [t("1", "Hook & Ladder 8", 40.71955, -74.00661),
                         t("2", "The Ghostbusters Firehouse", 40.71956, -74.00656)]}
    e6, g6, n6 = scan(doc6)
    check("unrelated titles 4 m apart are TIGHT", len(g6), 1)
    check("...and are invisible to NEAR", len(n6), 0)
    check("...and are not EXACT either", len(e6), 0)
    check("TIGHT reports the distance", 3 < g6[0][0] < 6, True)

    # A pair inside TIGHT must not ALSO be counted as NEAR, or the same site is
    # two findings.
    doc7 = {"tours": [t("1", "Centre Pompidou", 48.86070, 2.35222)],
            "linkPins": [t("2", "Centre Pompidou", 48.86064, 2.35224)], "places": []}
    e7, g7, n7 = scan(doc7)
    check("a same-subject pair inside TIGHT is reported once", (len(g7), len(n7)), (1, 0))

    # An existing place silences TIGHT exactly as it silences EXACT.
    doc7["places"] = [{"id": "p", "name": "Centre Pompidou", "tourIds": ["1", "2"]}]
    check("an existing place silences TIGHT", len(scan(doc7)[1]), 0)

    # 🔴 Do NOT bucket by city: a place spans a city label. These two are 4 m
    # apart across the East River's naming, not 4 m apart in the same string.
    doc8 = {"tours": [t("1", "Foo", 40.71955, -74.00661, city="New York")],
            "linkPins": [t("2", "Bar", 40.71956, -74.00656, city="Brooklyn")],
            "places": []}
    check("TIGHT crosses a city label", len(scan(doc8)[1]), 1)

    # The grid must not miss a pair that straddles a cell boundary. Placing one
    # marker either side of an exact multiple of the cell size is the case a
    # naive single-cell scan drops.
    cell = DEFAULT_RADIUS_M / 111_320.0
    edge = cell * 1000                     # an exact cell boundary in latitude
    doc9 = {"tours": [t("1", "Edge", edge - 0.00002, 10.0)],
            "linkPins": [t("2", "Edge Case", edge + 0.00002, 10.0)], "places": []}
    check("a pair across a grid boundary is still found", len(scan(doc9)[1]), 1)

    # --- a pin and a tour are treated alike
    doc5 = {"tours": [t("1", "Foo", 10.0, 20.0)],
            "linkPins": [t("2", "Foo", 10.0, 20.0)], "places": []}
    check("a pin can form a place with a tour", len(scan(doc5)[0]), 1)

    total = len(ran)
    if fails:
        print(f"SELFTEST FAILED — {len(fails)}/{total}")
        for f in fails:
            print("  ✗", f)
        return 1
    print(f"SELFTEST OK — {total}/{total}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("catalog", nargs="?",
                    default="TRAVEL GUIDED TOUR/Resources/Tours.json")
    ap.add_argument("--radius", type=float, default=DEFAULT_RADIUS_M,
                    help=f"NEAR-tier search radius in metres (default {DEFAULT_RADIUS_M:.0f})")
    ap.add_argument("--tight", type=float, default=DEFAULT_TIGHT_M,
                    help=f"TIGHT-tier radius in metres (default {DEFAULT_TIGHT_M:.0f})")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()
    # Stamp before any work, so a report can never be mistaken for a fresh one.
    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            return report(json.load(fh), a.radius, a.tight)
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
