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

2. **NEAR** — same-subject titles within `--radius` that are NOT coincident.
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
import re
import sys

DEFAULT_RADIUS_M = 500.0

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


def scan(doc, radius_m=DEFAULT_RADIUS_M):
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

    near = []
    for i, (k1, a) in enumerate(items):
        for k2, b in items[i + 1:]:
            dist = haversine(marker(a), marker(b))
            if dist == 0 or dist > radius_m:
                continue                      # 0 is the EXACT tier's business
            if a["id"] in claimed and b["id"] in claimed:
                continue
            if same_subject(a, b):
                near.append((dist, (k1, a), (k2, b)))
    near.sort(key=lambda r: r[0])
    return exact, near


def report(doc, radius_m=DEFAULT_RADIUS_M, out=sys.stdout):
    exact, near = scan(doc, radius_m)

    if exact:
        out.write(f"\nEXACT — {len(exact)} coincident group(s) with no place page.\n")
        out.write("  These meet the catalogue's own identity rule. Put them to the owner.\n")
        for coord, members in exact:
            out.write(f"\n  {coord[0]}, {coord[1]}\n")
            for kind, t in members:
                out.write(f"     [{kind:<4}] {t['title'][:56]:<57} {t.get('city')}\n")
    else:
        out.write("\nEXACT — none. Every coincident group is already a place.\n")

    if near:
        out.write(f"\nNEAR — {len(near)} same-subject pair(s) within {radius_m:.0f} m, not coincident.\n")
        out.write("  🔴 Never auto-create these. Read each one; some are deliberately separate.\n")
        for dist, (k1, a), (k2, b) in near:
            out.write(f"  {dist:7.0f}m  [{k1}] {a['title'][:34]:<35} | "
                      f"[{k2}] {b['title'][:34]:<35} {a.get('city')}\n")
    else:
        out.write(f"\nNEAR — none within {radius_m:.0f} m.\n")

    out.write(f"\n{len(exact)} exact, {len(near)} near.\n")
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
    exact, near = scan(doc)
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
    e2, n2 = scan(doc2)
    check("same subject nearby is NEAR", len(n2), 1)
    check("same subject nearby is not EXACT", len(e2), 0)
    check("distance is roughly right", 60 < n2[0][0] < 80, True)

    # Different subjects at the same distance must NOT be reported.
    doc3 = {"tours": [t("1", "Portsmouth Square", 37.7919, -122.4127),
                      t("2", "Waverly Place", 37.79182, -122.41349)],
            "linkPins": [], "places": []}
    check("different subjects nearby are ignored", len(scan(doc3)[1]), 0)

    # Beyond the radius, even the same subject is out of scope.
    doc4 = {"tours": [t("1", "Chinatown", 37.7919, -122.4127),
                      t("2", "Chinatown", 37.8100, -122.4127)],
            "linkPins": [], "places": []}
    check("beyond the radius is ignored", len(scan(doc4, radius_m=500)[1]), 0)

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
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    with open(a.catalog, encoding="utf-8") as fh:
        return report(json.load(fh), a.radius)


if __name__ == "__main__":
    sys.exit(main())
