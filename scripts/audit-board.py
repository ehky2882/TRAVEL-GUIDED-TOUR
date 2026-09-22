#!/usr/bin/env python3
"""The whole defect surface of the catalogue, on one screen.

WHY THIS EXISTS
---------------
Every gap in this catalogue has been found the same way: **the owner noticed
something on a map.** Torre Velasca pinned in Rome. Kossar's and Una Pizza with
no place. The Washington Monument sitting 7 m outside its own place. Each time
the answer was a new one-off check, and each time the NEXT gap was invisible
until a person tripped over it.

The owner's ask was exact: *"there should be a full and robust checklist to go
through."*

🔴 **So this file enumerates the defect CLASSES, not the defects.** A class with
no check is the dangerous thing — it is the shape of the next incident — and it
is printed here in the same list as the covered ones rather than being absent.

⚠️ **The counts live here; the explanations live in `docs/audit-checklist.md`.**
`CLAUDE.md` § READ FIRST: never report perishable state from a document. A count
written into prose is wrong by the next merge.

⚠️ **A count is not a defect count.** Several classes are dominated by legitimate
entries — a walk and a single-stop tour sharing one hero is editorial, and one
creator post pinned to five antique markets is the designed shape of a link pin.
Each row says what its number MEANS.
"""

from __future__ import annotations

import argparse
import collections
import json
import math
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")

JOIN_RADIUS_M = 25.0          # the repo's reviewed coincidence threshold
CITY_NEAR_KM = 30.0           # two spellings of one city cannot be far apart


def fold(text):
    """Lowercase, strip accents, keep letters and digits only."""
    stripped = "".join(c for c in unicodedata.normalize("NFKD", (text or "").lower())
                       if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", stripped)


def metres(lat1, lon1, lat2, lon2):
    return math.hypot((lat1 - lat2) * 111_320.0,
                      (lon1 - lon2) * 111_320.0 * math.cos(math.radians(lat1)))


def marker(entry):
    stop = (entry.get("stops") or [{}])[0]
    return stop.get("latitude"), stop.get("longitude")


def entries(doc):
    return (doc.get("tours") or []) + (doc.get("linkPins") or [])


# ---------------------------------------------------------------- the classes

def unjoined_places(doc, radius_m=JOIN_RADIUS_M):
    """🔴 Entries sitting ON an existing place that are not members of it.

    NOTHING in the repo asked this question before 2026-09-18. Every tier of
    `check-place-candidates.py` hunts for sites that have NO place page; the
    moment a place exists the site is treated as finished, and an entry landing
    on it afterwards is never questioned again.

    The owner found the Washington Monument this way: a place with two members,
    and a third entry 7.0 m away carrying the place's exact name.
    """
    claimed = {t.upper() for p in (doc.get("places") or [])
               for t in (p.get("tourIds") or [])}
    places = [p for p in (doc.get("places") or [])
              if p.get("latitude") is not None]
    out = []
    for entry in entries(doc):
        if entry["id"].upper() in claimed:
            continue
        lat, lon = marker(entry)
        if lat is None:
            continue
        for place in places:
            gap = metres(lat, lon, place["latitude"], place["longitude"])
            if gap <= radius_m:
                out.append((gap, entry, place))
    return sorted(out, key=lambda row: row[0])


def same_name_as_place(doc, rows=None):
    """The subset of `unjoined_places` carrying the place's EXACT name.

    ⚠️ Deliberately separate. Proximity alone is not identity — the owner has
    declined the Channel Gardens at Rockefeller Center and the Blue Ribbon
    Garden at Walt Disney Concert Hall, both of which are inside this radius.
    A matching name is the signal; the distance only bounds the search.
    """
    if rows is None:
        rows = unjoined_places(doc)
    out = []
    for gap, entry, place in rows:
        if fold(entry.get("title")) and fold(entry.get("title")) == fold(place.get("name")):
            out.append((gap, entry, place))
    return out


def city_spelled_twice(doc, near_km=CITY_NEAR_KM):
    """🔴 One city under two spellings — counted as two cities, forever.

    `CLAUDE.md` records `Sao Paulo`/`São Paulo` and `Zurich`/`Zürich` being
    merged, and asks for an accent-folded check in any batch that authors a
    city name. That covers accents. It does NOT cover `Washington` against
    `Washington, D.C.`, which is a PREFIX, not an accent — and that one is
    live in the catalogue right now.

    ⚠️ Proximity is required: `York` is a prefix of `New York` and they are
    different cities 5,000 km apart.
    """
    seen = collections.defaultdict(list)
    for entry in entries(doc):
        city = (entry.get("city") or "").strip()
        lat, lon = marker(entry)
        if city and lat is not None:
            seen[city].append((lat, lon, entry.get("country")))
    names = sorted(seen)
    out = []
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            fa, fb = fold(a), fold(b)
            if not fa or not fb:
                continue
            # 🔴 `fa == fb` on DIFFERENT raw spellings is the strongest finding
            # there is — `Zurich`/`Zürich`, `Sao Paulo`/`São Paulo`. An earlier
            # version skipped exactly those, silently, while claiming to check
            # for them. Only an identical RAW name is a non-event, and the
            # grouping above already makes that impossible.
            if not (fa.startswith(fb) or fb.startswith(fa)):
                continue
            la, loa, ca = seen[a][0]
            lb, lob, cb = seen[b][0]
            if ca != cb:
                continue
            if metres(la, loa, lb, lob) <= near_km * 1000:
                out.append((a, len(seen[a]), b, len(seen[b])))
    return out


def is_walk(entry):
    """A multi-stop walk, whose hero is legitimately ONE of its stops."""
    return (entry.get("kind") == "walk") or len(entry.get("stops") or []) > 1


def hero_shared_across_subjects(doc):
    """🔴 One image file standing in for MORE THAN ONE subject.

    The London Natural History Museum tour played Los Angeles' narration for
    six and a half weeks because both used the bare slug
    `natural-history-museum`. `check-image-duplicates.py` reports every shared
    URL, and most are fine, so the question is which sharing is a defect.

    🔴 THE FIRST ANSWER HERE WAS WRONG, AND THE VISION CHECK PROVED IT.
    This excused a shared hero whenever the entries came from ONE creator post
    — "the designed shape of a link pin". The sharing is indeed by design. The
    RESULT is not: one video about five Italian antique markets became five
    pins in five cities sharing one photograph, and that photograph shows the
    **Duomo di Lucca**. Four of the five show a different city's market. Worth
    Monument is the same shape — one post, three New York obelisks, one photo,
    and the photo is Cleopatra's Needle.

    **A photograph can depict at most ONE subject, whatever it was attached
    to.** Where the file came from says nothing about how many entries it can
    honestly serve.

    So the rule is about subjects, not provenance:

      * a **walk** legitimately shows one of its own stops, so a group with at
        most one non-walk entry is fine — that is the Trevi Fountain pin beside
        "The Baroque Heart" walk;
      * entries about the **same subject** may share a photograph — the Empire
        State Building tour and the Empire State Building pin;
      * **two or more standalone entries with different subjects cannot all be
        right**, and that is the finding, in one city or five.
    """
    by_hero = collections.defaultdict(list)
    for entry in entries(doc):
        if entry.get("heroImageURL"):
            by_hero[entry["heroImageURL"]].append(entry)
    out = []
    for url, group in by_hero.items():
        standalone = [e for e in group if not is_walk(e)]
        # ⚠️ No `len(group) < 2` guard: a one-entry group yields at most one
        # standalone, which this rejects anyway. Mutation testing showed
        # deleting it changed nothing, which is what a dead guard looks like.
        # This one is NOT dead — it is the only thing stopping a group of two
        # WALKS sharing a hero from being reported, where the title set is
        # empty and the same-subject test below cannot fire.
        if len(standalone) < 2:
            continue                  # a walk may show one of its own stops
        if len({fold(e.get("title")) for e in standalone}) == 1:
            continue                  # one subject, two entries — fine
        out.append((url, group))
    return out


def unverifiable_titles(doc):
    """Entries whose title nothing stored can corroborate.

    The class Torre Velasca was in: no venue `@handle`, and a caption sharing
    no word with the title. Only `check-pin-subject.py` can speak to these, and
    only with a key it is never given in CI.
    """
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "_pin_subject", os.path.join(HERE, "check-pin-subject.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.uncorroborated(doc)


# ------------------------------------------------------------------ the board

# Each row: (class, what covers it, where it runs, the function, what a count
# MEANS). 🔴 A class with no check keeps its row — that is the whole point.
ROWS = [
    ("Malformed entry / broken reference", "validate-tours.swift", "CI", None,
     "errors — any count is a defect"),
    ("Coordinate disagrees with a gazetteer", "spine-match.py", "CI", None,
     "DISAGREES — mostly the gazetteer's own error; not a worklist"),
    ("A site with two entries and no place", "check-place-candidates.py", "CI", None,
     "candidate groups — owner decides each"),
    # The INVERSE of the row above, and a class that had no check at all until
    # 2026-09-21: two entries we call by the same name, sitting in different
    # places. Agreement is the norm (158 of 164 groups within 100 m), so a
    # disagreement is a real question — but an extended site and a chain with
    # two branches both span legitimately, so it is never a defect count.
    ("Same name, different place", "check-same-name.py", "CI", None,
     "groups spanning >100 m — a stream or a chain spans legitimately"),
    # 🔴 The only row here covered by a check that asks NO external source. Every
    # lookup above is silent on the 2,901 entries Wikidata does not know, and
    # that blind spot is not random — many of those titles are stories, not
    # names ("A Greek Goddess on Fifth Avenue"), so more sources never reach
    # them. This asks the catalogue about itself, and found "Great Court,
    # British Museum" 58 km away in Great Notley, Essex, while UNMATCHED.
    ("Coordinate far from its own city", "check-city-outliers.py", "CI", None,
     "flagged — a question, not a defect count; Cape Point is 48 km out and right"),
    # 🔴 The creator SAID where they were. Only possible since the caption
    # recovery took location-marker captions from 535 to 914 — before that the
    # population was 13 rows and too noisy to automate. Tests the LOCALITY, not
    # the distance, per rule 8d: an address-only geocode would have moved the
    # correct Cube House pin 1.4 km.
    ("Caption names a city the pin disagrees with", "check-caption-address.py", "CI", None,
     "disagreements — a question; adjacent towns and street names dominate"),
    ("Coordinate implausible for its city", "check-coordinates.py", "by hand, on a drop", None,
     "GROSS — every one is a defect"),
    ("Image written under the wrong name", "check-image-duplicates.py", "by hand (network)", None,
     "byte-identical pairs — every one is a defect"),
    ("get_catalog dropped a key", "check-catalog-contract.py", "by hand (network)", None,
     "missing keys — every one is a silent feature loss"),
    ("Title does not match the picture", "check-pin-subject.py", "by hand (needs a key)", None,
     "CONTRADICTS — candidates, never a worklist"),
    ("🔴 Entry sits ON a place but is not a member", "audit-board.py (NEW)", "CI", unjoined_places,
     "within 25 m of an existing place — some are correctly out"),
    ("🔴   ...and carries the place's exact name", "audit-board.py (NEW)", "CI", same_name_as_place,
     "same name AND coincident — very likely a missed join"),
    ("🔴 One city spelled two ways", "audit-board.py (NEW)", "CI", city_spelled_twice,
     "spelling pairs — each splits one city into two"),
    ("🔴 One image standing in for two subjects", "audit-board.py (NEW)", "CI", hero_shared_across_subjects,
     "a photo depicts ONE subject — the rest are wrong, same post or not"),
    ("Title nothing stored can corroborate", "check-pin-subject.py", "by hand (needs a key)", unverifiable_titles,
     "the reachable-only-by-vision set; a count, not a defect count"),
]


def board(doc, out=sys.stdout):
    rows = []
    for name, tool, where, fn, means in ROWS:
        if fn is None:
            count = "—"
        else:
            try:
                count = str(len(fn(doc)))
            except Exception as exc:                        # noqa: BLE001
                count = f"ERR:{type(exc).__name__}"
        rows.append((name, tool, where, count, means))
    width = max(len(r[0]) for r in rows)
    out.write(f"\n{'class'.ljust(width)}  {'checked by':26} {'runs':22} {'n':>5}\n")
    out.write("-" * (width + 58) + "\n")
    for name, tool, where, count, means in rows:
        out.write(f"{name.ljust(width)}  {tool:26} {where:22} {count:>5}\n")
        out.write(f"{' ' * width}  └ {means}\n")
    return rows


def selftest():
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    def pin(eid, title, city, lat, lon, **kw):
        row = {"id": eid, "title": title, "city": city,
               "stops": [{"latitude": lat, "longitude": lon}]}
        row.update(kw)
        return row

    check("fold strips accents", fold("Zürich") == fold("Zurich"))
    check("fold strips punctuation and case",
          fold("Washington, D.C.") == "washingtondc")
    check("🔴 fold does NOT make two different cities equal",
          fold("York") != fold("New York"))

    # --- the join gap
    doc = {"tours": [], "linkPins": [
        pin("a", "Washington Monument", "Washington", 38.8895, -77.0353),
        pin("b", "Far Away", "Washington", 38.9500, -77.0353)],
        "places": [{"id": "p", "name": "Washington Monument", "city": "Washington",
                    "latitude": 38.8894375, "longitude": -77.0353125,
                    "tourIds": ["c"]}]}
    rows = unjoined_places(doc)
    check("🔴 an entry ON a place it does not belong to is found",
          [r[1]["id"] for r in rows] == ["a"])
    check("an entry far from the place is not", "b" not in [r[1]["id"] for r in rows])
    doc2 = json.loads(json.dumps(doc))
    doc2["places"][0]["tourIds"] = ["a"]
    check("🔴 an entry that IS a member is not reported",
          unjoined_places(doc2) == [])
    check("🔴 called with one argument it finds its own rows",
          len(same_name_as_place(doc)) == 1)
    check("🔴 the exact-name subset is narrower than proximity",
          len(same_name_as_place(doc, rows)) == 1
          and same_name_as_place(doc, [(1.0, pin("z", "Gift Shop", "Washington",
                                                 38.8895, -77.0353),
                                        doc["places"][0])]) == [])
    check("🔴 an entry with NO title does not match a place with no name",
          same_name_as_place(doc, [(1.0, pin("z", "", "Washington", 38.9, -77.0),
                                    {"name": "", "city": "Washington"})]) == [])
    check("case and accents do not defeat the name match",
          len(same_name_as_place(doc, [(1.0, pin("z", "WASHINGTON MONUMENT",
                                                 "Washington", 38.9, -77.0),
                                        doc["places"][0])])) == 1)

    # --- city spelled twice
    # 🔴 Each fixture isolates ONE rule: the pair must be excluded by the rule
    # under test and by nothing else. The first version of these tests had
    # every loosening mutant caught by a DIFFERENT guard, so four rules were
    # never exercised at all — the masking failure from #993, repeated.
    cities = {"tours": [], "linkPins": [
        pin("1", "x", "Washington", 38.889, -77.035, country="United States"),
        pin("2", "y", "Washington, D.C.", 38.890, -77.036, country="United States")],
        "places": []}
    got = city_spelled_twice(cities)
    check("🔴 a prefix spelling of one city is found",
          any({a, b} == {"Washington", "Washington, D.C."} for a, _, b, _ in got))

    # ⚠️ `York`/`New York` does NOT isolate proximity: York is a SUFFIX of New
    # York, so the prefix rule already excludes it and proximity never runs.
    # A true prefix pair, far apart, in one country, is what tests proximity.
    far_prefix = {"tours": [], "linkPins": [
        pin("1", "x", "Springfield", 39.80, -89.65, country="United States"),
        pin("2", "y", "Springfield, Missouri", 37.21, -93.29, country="United States")],
        "places": []}
    check("🔴 ONLY proximity separates two same-named cities 400 km apart",
          city_spelled_twice(far_prefix) == [])
    check("a suffix is not a prefix — York is not New York",
          city_spelled_twice({"tours": [], "places": [], "linkPins": [
              pin("1", "x", "York", 40.70, -74.01, country="United States"),
              pin("2", "y", "New York", 40.71, -74.00, country="United States")]}) == [])

    # prefix ✓, 1 km apart ✓ -> ONLY the country rule may exclude it
    cross_border = {"tours": [], "linkPins": [
        pin("1", "x", "Basel", 47.560, 7.590, country="Switzerland"),
        pin("2", "y", "Basel Nord", 47.566, 7.596, country="France")],
        "places": []}
    check("🔴 ONLY the country rule excludes a cross-border prefix",
          city_spelled_twice(cross_border) == [])

    # same country ✓, 1 km apart ✓, no prefix -> ONLY the prefix rule excludes
    unrelated = {"tours": [], "linkPins": [
        pin("1", "x", "Camden", 51.540, -0.143, country="United Kingdom"),
        pin("2", "y", "Islington", 51.546, -0.138, country="United Kingdom")],
        "places": []}
    check("🔴 ONLY the prefix rule keeps two neighbouring districts apart",
          city_spelled_twice(unrelated) == [])

    accents = {"tours": [], "linkPins": [
        pin("1", "x", "Zurich", 47.370, 8.540, country="Switzerland"),
        pin("2", "y", "Zürich", 47.376, 8.546, country="Switzerland")],
        "places": []}
    check("🔴 an ACCENT variant is reported — the Sao Paulo / São Paulo case",
          len(city_spelled_twice(accents)) == 1)
    check("one city under ONE spelling never pairs with itself",
          city_spelled_twice({"tours": [], "places": [], "linkPins": [
              pin("1", "x", "Springfield", 39.800, -89.600, country="United States"),
              pin("2", "y", "Springfield", 39.806, -89.606, country="United States")]}) == [])

    # --- one image standing in for more than one subject
    # 🔴 These fixtures encode the correction the vision check forced: sharing
    # a source post does NOT excuse a shared photograph, because a photograph
    # depicts one subject whatever it was attached to.
    heroes = {"tours": [], "places": [], "linkPins": [
        # one post, five markets, five cities, one photo of Lucca
        pin("1", "Mercato Antiquario di Lucca", "Lucca", 43.84, 10.50,
            heroImageURL="h1", sourceURL="onepost"),
        pin("2", "Fiera Antiquaria di Arezzo", "Arezzo", 43.46, 11.88,
            heroImageURL="h1", sourceURL="onepost"),
        # one post, three NYC obelisks, one photo — SAME city
        pin("3", "Worth Monument", "New York", 40.74, -73.99,
            heroImageURL="h2", sourceURL="obelisks"),
        pin("4", "Cleopatra's Needle", "New York", 40.77, -73.96,
            heroImageURL="h2", sourceURL="obelisks"),
        # a walk and the landmark it contains — legitimate
        dict(pin("5", "The Trevi Fountain", "Rome", 41.90, 12.48,
                 heroImageURL="h3", sourceURL="p1")),
        {"id": "6", "title": "The Baroque Heart", "city": "Rome", "kind": "walk",
         "heroImageURL": "h3", "sourceURL": "p2",
         "stops": [{"order": 0, "latitude": 41.90, "longitude": 12.48},
                   {"order": 1, "latitude": 41.91, "longitude": 12.47}]},
        # the same subject twice — a tour and a pin
        pin("7", "Empire State Building", "New York", 40.748, -73.985,
            heroImageURL="h4", sourceURL="p3"),
        pin("8", "Empire State Building", "New York", 40.748, -73.985,
            heroImageURL="h4", sourceURL="p4")]}
    found = [u for u, _ in hero_shared_across_subjects(heroes)]
    check("🔴 one post, five markets, five cities IS now reported",
          "h1" in found)
    check("🔴 one post, two obelisks in ONE city is reported too — the city "
          "was never the point", "h2" in found)
    check("🔴 a walk sharing its own stop's photo is NOT reported",
          "h3" not in found)
    check("🔴 the SAME subject twice may share a photo", "h4" not in found)
    # 🔴 Two WALKS sharing a hero: the title set is EMPTY, so the same-subject
    # test cannot fire and only the standalone minimum stops a false finding.
    two_walks = {"tours": [], "places": [], "linkPins": [
        {"id": "w1", "title": "Walk A", "city": "Rome", "kind": "walk",
         "heroImageURL": "hw", "stops": [{"order": 0, "latitude": 41.9,
                                          "longitude": 12.5}, {"order": 1,
                                          "latitude": 41.91, "longitude": 12.51}]},
        {"id": "w2", "title": "Walk B", "city": "Rome", "kind": "walk",
         "heroImageURL": "hw", "stops": [{"order": 0, "latitude": 41.9,
                                          "longitude": 12.5}, {"order": 1,
                                          "latitude": 41.92, "longitude": 12.52}]}]}
    check("🔴 two WALKS sharing a hero are not reported — only the standalone "
          "minimum can stop this one", hero_shared_across_subjects(two_walks) == [])
    check("is_walk sees an explicit kind",
          is_walk({"kind": "walk", "stops": []}) is True)
    check("is_walk sees a multi-stop entry with no kind",
          is_walk({"stops": [{}, {}]}) is True)
    check("a single-stop entry is not a walk", is_walk({"stops": [{}]}) is False)

    # --- the board itself
    import io
    buf = io.StringIO()
    printed = board({"tours": [], "linkPins": [], "places": []}, out=buf)
    check("the board prints a row per class", len(printed) == len(ROWS))
    check("🔴 a class with NO check still prints",
          any(r[3] == "—" for r in printed))
    check("every row says what its count means", all(r[4] for r in printed))
    # ⚠️ The earlier fixture here stopped raising once a signature was fixed,
    # and the test then asserted nothing while still reading green. A malformed
    # catalogue is the honest way to make a check fail.
    broken = board({"tours": [], "linkPins": [], "places": "not a list"},
                   out=io.StringIO())
    check("🔴 a check that raises reports ERR, never 0",
          any(str(r[3]).startswith("ERR") for r in broken))
    check("🔴 and the board still prints every other row",
          len(broken) == len(ROWS))

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{len(ran) - len(fails)}/{len(ran)}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--detail", default="",
                    help="print the rows behind one class: join, name, city, hero")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            doc = json.load(fh)

        if a.detail:
            fn = {"join": unjoined_places, "city": city_spelled_twice,
                  "hero": hero_shared_across_subjects}.get(a.detail)
            if a.detail == "name":
                rows = same_name_as_place(doc, unjoined_places(doc))
            elif fn:
                rows = fn(doc)
            else:
                print(f"unknown --detail {a.detail!r}")
                return 2
            for row in rows:
                print(" ", str(row)[:200] if not isinstance(row, tuple)
                      or len(row) != 3 else
                      f"{row[0]:6.1f}m  {(row[1].get('title') or '')[:44]:44}"
                      f" -> place {row[2].get('name')}")
            print(f"\n{len(rows)} row(s)")
            return 0

        board(doc)
        print("\n⚠️  A NUMBER HERE IS NOT A DEFECT COUNT. Read the line under each")
        print("    row: several classes are dominated by legitimate entries.")
        print("⚠️  A class with no check is the shape of the next incident. Every")
        print("    gap in this catalogue so far was found by the owner, on a map.")
        print("\n    docs/audit-checklist.md — what each class is and why it exists")
        print("    --detail join|name|city|hero — the rows behind a class")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
