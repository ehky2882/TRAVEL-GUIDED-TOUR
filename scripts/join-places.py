#!/usr/bin/env python3
"""Join an entry to a place that already exists.

🔴 THE OPERATION THAT WAS NEVER BUILT
--------------------------------------
`make-places.py` can CREATE a place from entries that have none. Nothing could
add an entry to a place that already exists — so every tier of
`check-place-candidates.py` hunts for sites with no place page, and the moment
a place exists that site reads as finished.

The owner found the hole: the **Washington Monument**, a place with two members
and a third entry sitting **7.0 m outside it**, carrying the place's exact name.
`audit-board.py` then measured it: **20 entries within 25 m of an existing
place, 10 of them carrying the place's exact name.**

🔴 A PLACE IS A COORDINATE, SO JOINING MOVES THE MEMBER
-------------------------------------------------------
`validate-tours.swift` errors unless every member's map pin sits on the place's
coordinate to 1e-7. So a join is two edits, not one:

    1. append the id to the place's `tourIds`
    2. MOVE the entry's marker stop onto the place's coordinate

⚠️ And the marker is **stop 0 of a walk**, not simply `stops[0]` — the validator
picks `order == 0`, and a walk's stops are not guaranteed to be in order.

⚠️ `Tour.coordinate` and the distance label read `centroidLatitude`, not the
stop, so both move or the entry shows one position and sorts by another.

GUARDS
------
Each exists because it is the way this goes wrong:

  * **`--max-move`** — a join that would drag an entry more than this is
    refused. `docs/places.md` records a 40 m proximity rule being measured and
    REJECTED (43 places, 19 wrong), so distance is never the argument.
  * **Name equality**, folded — not containment. Containment made
    `Municipal Library of Viana do Castelo` match the TOWN.
  * **The declined record** — `make-place-menu.py`'s three lists. The Channel
    Gardens sit inside Rockefeller Center and the owner said no; both are
    inside any radius this tool would use.
  * **Already a member** — refused, and the validator would catch it anyway
    ("already belongs to place").
"""

from __future__ import annotations

import argparse
import importlib.util
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

MAX_MOVE_M = 25.0


def _load(name, alias):
    spec = importlib.util.spec_from_file_location(alias, os.path.join(HERE, name))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fold(text):
    stripped = "".join(c for c in unicodedata.normalize("NFKD", (text or "").lower())
                       if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", stripped)


def metres(lat1, lon1, lat2, lon2):
    return math.hypot((lat1 - lat2) * 111_320.0,
                      (lon1 - lon2) * 111_320.0 * math.cos(math.radians(lat1)))


def marker_stop(entry):
    """The stop a map actually draws — `order == 0`, or the only stop.

    🔴 NOT `stops[0]`. `validate-tours.swift` picks the stop whose `order` is 0
    for a walk, and a walk's stops are not guaranteed to be stored in order.
    Moving the wrong stop leaves the validator's chosen marker where it was.
    """
    stops = entry.get("stops") or []
    if not stops:
        return None
    if (entry.get("kind") or "single") == "single" and len(stops) == 1:
        return stops[0]
    for stop in stops:
        if stop.get("order") == 0:
            return stop
    return None


# Words that name a CATEGORY rather than a subject. A caption saying "museum"
# proves nothing about WHICH museum.
GENERIC_NAME_WORDS = {
    "the", "of", "and", "a", "an", "de", "la", "le", "el", "di", "du", "des",
    "museum", "gallery", "centre", "center", "national", "art", "house",
    "building", "tower", "park", "garden", "church", "cathedral", "hotel",
    "restaurant", "cafe", "bar", "shop", "store", "market", "square",
}


def distinctive_words(place_name, city):
    """The words in a place's name that actually identify it.

    🔴 The CITY is dropped, and that is load-bearing rather than tidy. "The
    National Art Center, Tokyo" reduces to nothing but `tokyo` once the
    category words go, and a caption reading "the coolest cafe in a museum"
    contains `tokyo` in its own city field — so keeping it would let a caption
    that names NOTHING prove a join. An empty result must never count as
    "every word present".
    """
    folded_city = fold(city)
    out = []
    for word in re.split(r"[^\w]+", (place_name or "").lower()):
        if not word or len(word) < 2:
            continue                       # "R." in "Solomon R. Guggenheim"
        if word in GENERIC_NAME_WORDS:
            continue
        if fold(word) and fold(word) == folded_city:
            continue
        out.append(word)
    return out


def caption_names_place(entry, place):
    """Does the entry's own caption name this place? Returns a reason or "".

    🔴 WHY THIS EXISTS. The first join rule matched on TITLE equality, which
    joined ten entries and left seven that were never judgement calls -- they
    are pins TITLED WITH THE CREATOR'S CAPTION rather than a name, so no title
    test could ever see them. `@centrepompidou is the coolest museum ever` is
    not a name, and it is unmistakably about the Centre Pompidou.

    ⚠️ Folding removes spaces and punctuation, so an @handle matches the name
    it is built from: `@centrepompidou` folds to the same string as
    `Centre Pompidou`. That is deliberate, and it is how most of these read.
    """
    blob = " ".join([(entry.get("shortDescription") or ""),
                     (entry.get("longDescription") or "")])
    folded = fold(blob)
    if not folded:
        return ""
    name = place.get("name") or ""
    if fold(name) and fold(name) in folded:
        return "caption contains the whole name"
    words = distinctive_words(name, place.get("city"))
    if not words:
        return ""                          # 🔴 never "vacuously all present"
    if all(fold(w) in folded for w in words):
        return "caption contains every distinctive word"
    return ""


def declined_pairs():
    """Every pairing the owner has refused, from the machine-readable record.

    🔴 In #993 this guard failed on its first run — the code was right and the
    DATA was missing: nine decisions existed only as prose in `docs/places.md`.
    Read the record, never the document.
    """
    menu = _load("make-place-menu.py", "_place_menu")
    out = set()
    for attr in ("DECLINED", "DECLINED_GROUPS", "DECLINED_PAIRS"):
        for item in getattr(menu, attr, ()) or ():
            names = [item] if isinstance(item, str) else list(item)
            for name in names:
                if isinstance(name, str):
                    out.add(fold(name))
    return out


def candidates(doc, max_move_m=MAX_MOVE_M):
    """Entries that should join a place: coincident AND named, by title or caption.

    Two independent signals, either sufficient, both narrow:
      * the entry's TITLE equals the place's name, or
      * the entry's CAPTION names the place.
    """
    board = _load("audit-board.py", "_audit_board")
    refused = declined_pairs()
    out = []
    # ⚠️ The radius is passed THROUGH, not applied afterwards. Filtering the
    # board's default 25 m result would let `--max-move` narrow and never
    # widen — a flag that silently ignores half its range. A selftest asking
    # for 5,000 m is what found that.
    near = board.unjoined_places(doc, max_move_m)
    by_title = {id(r[1]) for r in board.same_name_as_place(doc, near)}
    rows = [r for r in near
            if id(r[1]) in by_title or caption_names_place(r[1], r[2])]
    for gap, entry, place in rows:
        # ⚠️ No second distance filter here. `unjoined_places` already bounds
        # the search at `max_move_m`, so a filter after it could never fire —
        # mutation testing showed deleting it changed nothing, which is the
        # definition of a line that is not a guard.
        if fold(entry.get("title")) in refused or fold(place.get("name")) in refused:
            continue
        out.append((gap, entry, place))
    return out


def apply_join(doc, entry, place):
    """Append the id and MOVE the entry onto the place. Returns what changed.

    ⚠️ The id is appended, never sorted in: a sorted `tourIds` turned a 23-place
    addition into 4,048 insertions across 1,570 coordinate lines in #993.
    """
    stop = marker_stop(entry)
    if stop is None:
        raise ValueError(f"{entry.get('title')!r} has no stop that draws a pin")
    lat, lon = place["latitude"], place["longitude"]
    moved = metres(stop["latitude"], stop["longitude"], lat, lon)
    stop["latitude"], stop["longitude"] = lat, lon
    # Tour.coordinate and the distance label read the centroid, not the stop.
    if "centroidLatitude" in entry:
        entry["centroidLatitude"], entry["centroidLongitude"] = lat, lon
    place.setdefault("tourIds", []).append(entry["id"])
    return moved


def selftest():
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    def walk(eid, title, stops):
        return {"id": eid, "title": title, "city": "X", "kind": "walk",
                "stops": stops, "centroidLatitude": stops[0]["latitude"],
                "centroidLongitude": stops[0]["longitude"]}

    def single(eid, title, lat, lon):
        return {"id": eid, "title": title, "city": "X", "kind": "single",
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}],
                "centroidLatitude": lat, "centroidLongitude": lon}

    # 🔴 stops deliberately OUT of order: the marker is `order == 0`, not [0].
    out_of_order = walk("w", "W", [
        {"order": 2, "latitude": 10.0, "longitude": 20.0},
        {"order": 0, "latitude": 11.0, "longitude": 21.0},
        {"order": 1, "latitude": 12.0, "longitude": 22.0}])
    check("🔴 the marker of a walk is order 0, NOT stops[0]",
          marker_stop(out_of_order)["order"] == 0)
    check("a single's only stop is its marker",
          marker_stop(single("s", "S", 1.0, 2.0))["latitude"] == 1.0)
    check("an entry with no stops has no marker", marker_stop({"stops": []}) is None)

    place = {"id": "p", "name": "Washington Monument", "city": "Washington",
             "latitude": 38.8894375, "longitude": -77.0353125, "tourIds": ["m"]}
    entry = single("a", "Washington Monument", 38.8895, -77.0353)
    moved = apply_join({}, entry, place)
    stop = marker_stop(entry)
    check("🔴 the member lands EXACTLY on the place, to 1e-7",
          abs(stop["latitude"] - place["latitude"]) < 1e-9
          and abs(stop["longitude"] - place["longitude"]) < 1e-9)
    check("🔴 the CENTROID moves too — the map marker reads it",
          entry["centroidLatitude"] == place["latitude"]
          and entry["centroidLongitude"] == place["longitude"])
    check("the id is APPENDED, never sorted in", place["tourIds"] == ["m", "a"])
    check("the distance moved is reported", 0 < moved < 25)

    # a walk joins by its order-0 stop, and its other stops must NOT move
    place2 = {"id": "p2", "name": "W", "latitude": 11.0001, "longitude": 21.0001,
              "tourIds": []}
    before = [(s["order"], s["latitude"]) for s in out_of_order["stops"]
              if s["order"] != 0]
    apply_join({}, out_of_order, place2)
    after = [(s["order"], s["latitude"]) for s in out_of_order["stops"]
             if s["order"] != 0]
    check("🔴 a walk's OTHER stops are left exactly where they were",
          before == after)

    # ⚠️ "it raised" is too weak: deleting the guard still raises, from a
    # TypeError deeper in. The refusal must be the deliberate one.
    before_ids = list(place["tourIds"])
    check("🔴 an entry with no drawable stop is REFUSED, by name",
          _raises(lambda: apply_join({}, {"id": "x", "stops": []}, place),
                  ValueError))
    check("...and the place is left untouched by the refusal",
          place["tourIds"] == before_ids)

    # --- candidates
    doc = {"tours": [], "linkPins": [
        single("a", "Washington Monument", 38.8895, -77.0353),
        single("b", "Gift Shop", 38.8895, -77.0353),
        single("c", "Washington Monument", 38.9200, -77.0353)],
        "places": [{"id": "p", "name": "Washington Monument", "city": "Washington",
                    "latitude": 38.8894375, "longitude": -77.0353125,
                    "tourIds": ["m"]}]}
    got = [e["id"] for _, e, _ in candidates(doc)]
    check("🔴 the same-named coincident entry IS a candidate", "a" in got)
    check("a differently-named neighbour is NOT", "b" not in got)
    check("🔴 a same-named entry too far away is NOT", "c" not in got)
    # 🔴 A pin whose TITLE proves nothing and whose CAPTION proves everything.
    # Without this, `candidates` could drop the caption signal entirely and
    # every test still passed — the unit tests covered caption_names_place,
    # nothing covered its use.
    caption_only = {"tours": [], "linkPins": [
        dict(single("cap", "@centrepompidou is the coolest museum ever",
                    48.8607, 2.3522),
             longDescription="@centrepompidou is the coolest museum ever")],
        "places": [{"id": "p", "name": "Centre Pompidou", "city": "Paris",
                    "latitude": 48.8607, "longitude": 2.3522,
                    "tourIds": ["m"]}]}
    check("🔴 a pin proved ONLY by its caption is a candidate",
          [e["id"] for _, e, _ in candidates(caption_only)] == ["cap"])
    no_proof = json.loads(json.dumps(caption_only))
    no_proof["linkPins"][0]["longDescription"] = "the coolest cafe in a museum"
    check("🔴 the same pin with a caption naming nothing is NOT",
          candidates(no_proof) == [])

    check("🔴 --max-move is what excludes it, and it is honoured",
          "c" in [e["id"] for _, e, _ in candidates(doc, max_move_m=5000)])

    accented = {"tours": [], "linkPins": [
        single("a", "Pinacoteca de Sao Paulo", -23.5346, -46.6336)],
        "places": [{"id": "p", "name": "Pinacoteca de São Paulo",
                    "city": "São Paulo", "latitude": -23.5346,
                    "longitude": -46.6336, "tourIds": ["m"]}]}
    check("🔴 an accent difference does not defeat the name match",
          len(candidates(accented)) == 1)

    # --- the caption signal
    pl = {"name": "Centre Pompidou", "city": "Paris"}
    def cap(text):
        return {"id": "x", "title": "whatever", "longDescription": text}
    check("🔴 an @handle names the place — folding removes the space",
          caption_names_place(cap("@centrepompidou is the coolest museum"), pl))
    check("the written-out name works too",
          caption_names_place(cap("we visited the Centre Pompidou"), pl))
    check("🔴 a caption naming NOTHING proves nothing",
          caption_names_place(cap("the coolest cafe in a museum"), pl) == "")
    check("an empty caption proves nothing", caption_names_place(cap(""), pl) == "")

    tokyo = {"name": "The National Art Center, Tokyo", "city": "Tokyo"}
    check("🔴 a name that is ONLY category words plus its city can never be "
          "proved — an empty word list is not 'all present'",
          caption_names_place(cap("the coolest cafe in a museum in Tokyo"),
                              tokyo) == "")
    check("distinctive_words drops the city",
          "tokyo" not in distinctive_words("The National Art Center, Tokyo", "Tokyo"))
    check("distinctive_words drops category words",
          distinctive_words("The Guggenheim Museum", "New York") == ["guggenheim"])
    check("🔴 distinctive_words drops a one-letter initial",
          "r" not in distinctive_words("Solomon R. Guggenheim Museum", "New York"))
    check("every distinctive word must be present, not merely one",
          caption_names_place(cap("the Guggenheim reopened"),
                              {"name": "Solomon R. Guggenheim Museum",
                               "city": "New York"}) == "")

    refused = declined_pairs()
    check("🔴 the declined record is non-empty — a guard reading an empty "
          "record refuses nothing", len(refused) > 0)
    check("🔴 the Channel Gardens are in it (declined at Rockefeller Center)",
          fold("The Channel Gardens") in refused)
    doc2 = json.loads(json.dumps(doc))
    doc2["linkPins"][0]["title"] = "The Channel Gardens"
    doc2["places"][0]["name"] = "The Channel Gardens"
    check("🔴 a declined name is refused even when coincident and same-named",
          candidates(doc2) == [])

    # 🔴 In THIS tool `fold` decides one thing only: whether a title matches the
    # declined record. (The name match itself is audit-board's fold.) So the
    # accent test that matters here is a declined name reached through an
    # accent variant — otherwise nothing exercises this fold at all, and a
    # mutation removing its accent stripping survives.
    doc3 = json.loads(json.dumps(doc))
    doc3["linkPins"][0]["title"] = "Thé Channel Gàrdens"
    doc3["places"][0]["name"] = "Thé Channel Gàrdens"
    check("🔴 accents do not let an entry slip PAST the declined record",
          candidates(doc3) == [])

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{len(ran) - len(fails)}/{len(ran)}")
    return 1 if fails else 0


def _raises(fn, kind=Exception):
    try:
        fn()
    except kind:
        return True
    except Exception:                                       # noqa: BLE001
        return False        # raised, but not the refusal we asked for
    return False


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--max-move", type=float, default=MAX_MOVE_M)
    ap.add_argument("--apply", action="store_true",
                    help="write the joins; without it, only report")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            doc = json.load(fh)
        rows = candidates(doc, a.max_move)
        print(f"{len(rows)} entry(ies) to join\n")
        for gap, entry, place in rows:
            print(f"  {gap:5.1f}m  {(entry.get('title') or '')[:42]:42} "
                  f"-> {place.get('name')} ({place.get('city')})")
        if not a.apply:
            print("\nreport only — pass --apply to write")
            return 0
        for gap, entry, place in rows:
            apply_join(doc, entry, place)
        with open(a.catalog, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print(f"\napplied {len(rows)} join(s)")
        print("⚠️  Now run `swift scripts/validate-tours.swift` — it is the only")
        print("    mechanical check that a member sits on its place.")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
