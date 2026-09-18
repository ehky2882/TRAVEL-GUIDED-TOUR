#!/usr/bin/env python3
"""Create places from a shared Wikidata id — the first auto-creation path.

WHY THIS IS ALLOWED TO CREATE WITHOUT ASKING
---------------------------------------------
`Models/Place.swift` says identity is exact coordinate equality and *"anything
looser must be approved by a human, never auto-created"*. That rule was written
because the only looser test available at the time was PROXIMITY, and proximity
was measured and rejected: grouping anything within 40 m produced 43 places of
which **19 were wrong** — it merged LACMA with the Academy Museum and chained
three separate La Boca venues into one site.

**A shared gazetteer id is not a looser version of that test. It is a different
one.** Two entries are grouped here only when Wikidata's own search resolves
both to the **same item**, and both sit within 120 m of that item's coordinate.
Nothing is inferred from how close the two entries are to each other: `The
Shard` and `The Shard` are one place because they are the same building, which
is exactly `docs/places.md` Rule 1 — *two names for one thing is always a
place* — decided by a gazetteer instead of by eye.

⚠️ **This does NOT settle part-vs-whole**, which `docs/places.md` leaves
explicitly undecided. A gazetteer has no opinion on whether the River Building
is Grace Farms. Those cases still go to the owner.

🔴 THE DECLINED LIST IS NOT OPTIONAL
-------------------------------------
The first run of this proposed **Bar Luce at Fondazione Prada** + **Fondazione
Prada** — a pairing the owner has already declined under Rule 4, *a tenant is
not the site*. Wikidata cannot know that Bar Luce is a café inside the
foundation; it resolves both to the foundation and is, on its own terms,
correct.

So every proposal is checked against `make-place-menu.py`'s `DECLINED`,
`DECLINED_GROUPS` and `DECLINED_PAIRS` — the record of ~60 owner decisions —
and a match is **refused, not merely flagged**. Those lists are keyed by TITLE
rather than by any generated label, deliberately, so they survive renumbering.

WHAT CREATING A PLACE ACTUALLY DOES
------------------------------------
🔴 **A place is a COORDINATE, so creating one MOVES every member onto a single
point.** `validate-tours.swift` errors if a member's `order == 0` stop is not
within 1e-7° of it. This uses the **Wikidata item's own coordinate** as that
point, which is the honest choice: it is what both entries were independently
matched against.

⚠️ Measured on the first run: median member move **22 m**, maximum **86 m** —
inside the 30 m default `triggerRadiusMeters` for most, and small enough that no
geofence moves off its own building. `--max-move` refuses anything further, so a
group that would drag an entry somewhere new fails loudly instead of quietly.
"""

from __future__ import annotations

import argparse
import collections
import gzip
import importlib.util
import json
import os
import re
import sys
import unicodedata
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "spine", "lookups.json.gz")
FEATURES = os.path.join(REPO, "spine", "features.json.gz")

MAX_MOVE_M = 120.0      # a member further than this is a group worth reading


def _load(name, alias):
    path = os.path.join(HERE, name)
    spec = importlib.util.spec_from_file_location(alias, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_sm = _load("spine-match.py", "_spine_match")
_menu = _load("make-place-menu.py", "_place_menu")
haversine = _sm._cpc.haversine


def slug(text):
    """The place-id slug. Matches the scheme that reproduces the live ids.

    ⚠️ Deliberately does NOT transliterate: `Chichén Itzá` becomes
    `chich-n-itz`. Ugly, and correct — it is the rule the existing ids were
    minted under, and changing it would orphan them.
    """
    lowered = unicodedata.normalize("NFC", (text or "")).lower()
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", lowered)).strip("-")


def place_id(city, name):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"atlas-place:{slug(city)}:{slug(name)}"))


def declined(titles):
    """Has the owner already said no to this exact set of titles?

    🔴 Checked three ways because the record is kept three ways, and a proposal
    only has to match ONE of them to be refused.
    """
    as_set = frozenset(titles)
    if as_set in _menu.DECLINED_GROUPS:
        return "an owner-declined group"
    for pair in _menu.DECLINED_PAIRS:
        if frozenset(pair) <= as_set:
            return "an owner-declined pair"
    for title in titles:
        if title in _menu.DECLINED:
            return f"an owner-declined entry ({title})"
    return None


def propose(catalog, cache, features, *, max_move_m=MAX_MOVE_M):
    """Groups of entries that resolve to one Wikidata item. Returns (make, skip)."""
    rows = _sm.classify(catalog, cache, features)
    claimed = {t for p in (catalog.get("places") or []) for t in p.get("tourIds", [])}

    by_item = collections.defaultdict(list)
    for row in rows:
        if row["band"] == "CONFIRMS" and row["best"]:
            by_item[row["best"]["qid"]].append(row)

    make, skip = [], []
    for qid, group in sorted(by_item.items()):
        if len(group) < 2:
            continue
        titles = [r["entry"].get("title") or "" for r in group]
        anchor = group[0]["best"]
        point = (anchor["lat"], anchor["lon"])
        moves = [haversine(_sm.entry_marker(r["entry"]), point) for r in group]
        cities = [r["entry"].get("city") for r in group if r["entry"].get("city")]
        item = {
            "qid": qid, "name": anchor["label"], "titles": titles,
            "city": cities[0] if cities else None,
            "lat": point[0], "lon": point[1],
            "members": [r["entry"]["id"] for r in group],
            "max_move_m": max(moves),
        }

        if any(m["entry"]["id"] in claimed for m in group):
            # Partially or fully placed already — joining an existing place is a
            # different operation, and one that changes a place people can see.
            item["why"] = "a member already belongs to a place"
            skip.append(item)
            continue
        reason = declined(titles)
        if reason:
            item["why"] = f"REFUSED — {reason}"       # 🔴 never silently minted
            skip.append(item)
            continue
        if max(moves) > max_move_m:
            item["why"] = f"a member would move {max(moves):.0f} m"
            skip.append(item)
            continue
        make.append(item)
    return make, skip


def apply(catalog, make):
    """Mint the places and move every member onto the shared point."""
    entries = {e["id"]: e for e in _sm.entries(catalog)}
    places = catalog.setdefault("places", [])
    existing = {p["id"] for p in places}
    minted = 0
    for item in make:
        pid = place_id(item["city"] or "", item["name"])
        if pid in existing:
            continue                                   # id collision: leave it
        for member in item["members"]:
            entry = entries[member]
            stops = entry.get("stops") or []
            target = next((s for s in stops if s.get("order") == 0), stops[0])
            target["latitude"] = item["lat"]
            target["longitude"] = item["lon"]
            # `Tour.coordinate` and the distance label read the CENTROID, not
            # stop 0 — #930 moved 26 coordinates and no centroids, leaving the
            # pin in one place and every distance in another.
            if "centroidLatitude" in entry:
                entry["centroidLatitude"] = item["lat"]
                entry["centroidLongitude"] = item["lon"]
        places.append({
            "id": pid, "name": item["name"], "description": None,
            "latitude": item["lat"], "longitude": item["lon"],
            "city": item["city"], "address": None,
            "heroImageURL": None, "additionalImageURLs": None,
            "tourIds": item["members"],
        })
        existing.add(pid)
        minted += 1
    places.sort(key=lambda p: p["id"])
    return minted


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    check("slug is lowercase and hyphenated", slug("The Shard!") == "the-shard")
    check("🔴 slug does NOT transliterate — it must reproduce the live ids",
          slug("Chichén Itzá") == "chich-n-itz")
    check("place_id is stable",
          place_id("London", "The Shard") == place_id("London", "The Shard"))
    check("place_id differs by city",
          place_id("London", "X") != place_id("Paris", "X"))

    # 🔴 The guard the first live run demanded.
    luce = ["Bar Luce at Fondazione Prada", "Fondazione Prada"]
    check("🔴 an owner-declined pairing is REFUSED", declined(luce) is not None)
    check("an ordinary pairing is not refused",
          declined(["The Shard", "The Shard"]) is None)
    check("the declined record is actually loaded, not an empty set",
          len(_menu.DECLINED_GROUPS) > 10 and len(_menu.DECLINED_PAIRS) > 0)

    def entry(eid, title, lat, lon, city="X"):
        return {"id": eid, "title": title, "city": city, "kind": "single",
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}

    cat = {"tours": [entry("a", "The Shard", 51.5045, -0.0865),
                     entry("b", "The Shard", 51.5046, -0.0866)],
           "linkPins": [], "places": []}
    cache = {eid: {"candidates": [{"qid": "Q18536", "label": "The Shard",
                                   "lat": 51.5045, "lon": -0.0865,
                                   "distance_m": d, "sitelinks": 50}]}
             for eid, d in (("a", 5.0), ("b", 12.0))}
    make, skip = propose(cat, cache, {})
    check("two entries on one item propose a place", len(make) == 1)
    check("the proposal carries both members", len(make[0]["members"]) == 2)

    minted = apply(cat, make)
    check("apply mints exactly one place", minted == 1 and len(cat["places"]) == 1)
    moved = [s["latitude"] for e in cat["tours"] for s in e["stops"]]
    check("🔴 apply MOVES every member onto the shared point",
          all(abs(v - 51.5045) < 1e-9 for v in moved))
    check("the place carries the gazetteer coordinate",
          abs(cat["places"][0]["latitude"] - 51.5045) < 1e-9)
    check("apply is idempotent", apply(cat, make) == 0)

    cat2 = json.loads(json.dumps(cat)); cat2["places"] = []
    cat2["tours"][1]["stops"][0]["latitude"] = 51.5200      # ~1.7 km away
    cache2 = json.loads(json.dumps(cache))
    make2, skip2 = propose(cat2, cache2, {}, max_move_m=120.0)
    check("🔴 a group that would drag a member too far is SKIPPED, not minted",
          make2 == [] and len(skip2) == 1 and "would move" in skip2[0]["why"])

    cat3 = json.loads(json.dumps(cat))
    check("an already-placed member is skipped",
          propose(cat3, cache, {})[0] == [])

    total = 16
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--features", default=FEATURES)
    ap.add_argument("--max-move", type=float, default=MAX_MOVE_M)
    ap.add_argument("--apply", action="store_true",
                    help="write the places into the catalogue (default: propose only)")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        for path in (a.cache, a.features):
            if not os.path.exists(path):
                print(f"COULD NOT VERIFY — missing {path}")
                return 2
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        with gzip.open(a.cache, "rt", encoding="utf-8") as fh:
            cache = json.load(fh)
        with gzip.open(a.features, "rt", encoding="utf-8") as fh:
            features = json.load(fh)

        make, skip = propose(catalog, cache, features, max_move_m=a.max_move)
        print(f"{len(make)} place(s) to create · {len(skip)} skipped\n")
        for item in sorted(make, key=lambda i: -len(i["members"])):
            print(f"  {len(item['members'])}x  {item['name'][:34]:34} "
                  f"{(item['city'] or '')[:14]:14} move<={item['max_move_m']:.0f} m")
            for title in item["titles"]:
                print(f"        · {title[:60]}")
        refused = [i for i in skip if i["why"].startswith("REFUSED")]
        if refused:
            print(f"\n🔴 REFUSED — the owner has already decided these:")
            for item in refused:
                print(f"  {item['name'][:34]:34} {item['why']}")

        if not a.apply:
            print("\n(proposal only — pass --apply to write them)")
            return 1 if make else 0

        minted = apply(catalog, make)
        with open(a.catalog, "w", encoding="utf-8") as fh:
            json.dump(catalog, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print(f"\nOK — created {minted} place(s); run validate-tours next")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
