#!/usr/bin/env python3
"""Refuse a pin title that nothing will ever be able to verify.

WHY
---
A pin's title is an assertion about what a place IS, and three title shapes
make that assertion permanently uncheckable. All three shipped, and all three
were found by the owner rather than by any check:

  1. **A CAPTION used as a title.**
     `"@centrepompidou is the coolest museum ever and that's a fact"`
     Seven such pins sat inside places they belonged to and no title rule could
     see them, because no title test matches a sentence. `@pasttworld` posts in
     this style by default: **67% of that creator's pins have captions naming
     no building**, against 15% catalogue-wide.

  2. **A DESCRIPTION used as a title.**
     `"A brutalist church, Via Dalmazia"`
     Gate B then asks "is this photograph *A brutalist church, Via Dalmazia*?",
     which is not an answerable question, and no gazetteer can resolve it
     either. Both such entries turned out to be named buildings —
     San Nicolao della Flüe and San Giovanni Bono.

  3. **A DUPLICATE title on a near-identical coordinate.**
     Two pins both titled `Grace Farms`, metres apart. One was Philip Johnson's
     **Glass House**. This shape is the most dangerous of the three because it
     looks like a textbook PLACE — identical name, zero distance — which is
     exactly what `check-place-candidates` is built to reward. A place was
     minted from it, and existed only to hold the mislabel.

🔴 THIS IS A GATE, NOT A REPORT. Every one of these was cheap to catch at
authoring time and expensive afterwards: a wrong title gets a coordinate chosen
to match it, then `relatedTourIds` built from that coordinate, then possibly a
place minted around it. Torre Velasca took four steps to unwind.

⚠️ It cannot tell whether a NAME is the RIGHT name — only that the title is the
kind of thing a name could be. `check-pin-subject.py` asks the picture; this
asks the grammar.
"""

from __future__ import annotations

import argparse
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

DUPLICATE_RADIUS_M = 60.0
MAX_TITLE_WORDS = 9


def fold(text):
    stripped = "".join(c for c in unicodedata.normalize("NFKD", (text or "").lower())
                       if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", stripped)


def metres(lat1, lon1, lat2, lon2):
    return math.hypot((lat1 - lat2) * 111_320.0,
                      (lon1 - lon2) * 111_320.0 * math.cos(math.radians(lat1)))


def looks_like_caption(title):
    """A sentence pretending to be a name. Returns a reason or ""."""
    text = (title or "").strip()
    if not text:
        return "empty title"
    if "@" in text:
        return "contains an @handle — that is a caption, not a name"
    if any(c in text for c in "?!"):
        return "contains ? or ! — that is a caption, not a name"
    if text.endswith(("…", "...")):
        return "ends in an ellipsis — a truncated caption"
    # ⚠️ Emoji are the single most reliable caption tell in this catalogue.
    if any(unicodedata.category(c) == "So" for c in text):
        return "contains an emoji — that is a caption, not a name"
    if len(text.split()) > MAX_TITLE_WORDS:
        return f"{len(text.split())} words — too long to be a name"
    return ""


def looks_like_description(title):
    """A description pretending to be a name.

    🔴 The rule is the INDEFINITE ARTICLE, and it is narrow on purpose. A place
    name essentially never begins with "A" or "An" — it is the grammar of a
    description ("a brutalist church") rather than of a name. "The" is NOT
    included: "The Glass House", "The Shard", "The Unisphere" are all real
    names, and a rule that caught those would be useless.
    """
    text = (title or "").strip()
    first = text.split(" ")[0].lower().strip(",") if text else ""
    if first in ("a", "an"):
        return f"starts with the indefinite article {first!r} — a description, not a name"
    return ""


def duplicate_nearby(entry, catalog, radius_m=DUPLICATE_RADIUS_M):
    """Another entry with the SAME title within `radius_m`. Reason or "".

    🔴 This is the Grace Farms shape, and it is the one that looks HEALTHIEST
    while being wrong: identical name at zero distance is exactly the signal a
    place is minted from.
    """
    title = fold(entry.get("title"))
    if not title:
        return ""
    stop = (entry.get("stops") or [{}])[0]
    lat, lon = stop.get("latitude"), stop.get("longitude")
    if lat is None:
        return ""
    others = (catalog.get("tours") or []) + (catalog.get("linkPins") or [])
    for other in others:
        if other.get("id") == entry.get("id"):
            continue
        if fold(other.get("title")) != title:
            continue
        ostop = (other.get("stops") or [{}])[0]
        olat, olon = ostop.get("latitude"), ostop.get("longitude")
        if olat is None:
            continue
        gap = metres(lat, lon, olat, olon)
        if gap <= radius_m:
            return (f"another entry titled the same sits {gap:.0f} m away — "
                    f"if they are different subjects, one title is wrong")
    return ""


def findings(entry, catalog=None, radius_m=DUPLICATE_RADIUS_M):
    out = []
    for check in (looks_like_caption, looks_like_description):
        reason = check(entry.get("title"))
        if reason:
            out.append(reason)
    if catalog is not None:
        reason = duplicate_nearby(entry, catalog, radius_m)
        if reason:
            out.append(reason)
    return out


def selftest():
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    # --- captions, every one a real title that shipped
    check("🔴 an @handle title is caught",
          looks_like_caption("@centrepompidou is the coolest museum ever"))
    check("🔴 an emoji title is caught",
          looks_like_caption("Hungary's Weirdest Skyscraper😱"))
    check("a question is caught", looks_like_caption("What's up with this building?"))
    check("an ellipsis is caught", looks_like_caption("Would you try this sandwich…"))
    check("a long sentence is caught",
          looks_like_caption("We love a good art history legend the fountain is called that"))
    check("an empty title is caught", looks_like_caption(""))

    # --- real names must survive, or the gate is useless
    for name in ("Centre Pompidou", "Sagrada Família", "The Glass House",
                 "Chiesa di San Giovanni Bono", "Le Relais de Venise",
                 "Tianjin CTF Finance Centre", "Kossar's",
                 "The National Art Center, Tokyo", "590 Lexington Avenue"):
        check(f"🔴 a real name survives: {name!r}", not looks_like_caption(name))

    # --- descriptions
    check("🔴 'A brutalist church, Via Dalmazia' is caught",
          looks_like_description("A brutalist church, Via Dalmazia"))
    check("'An old mill by the river' is caught",
          looks_like_description("An old mill by the river"))
    check("🔴 'The' is NOT the indefinite article — The Glass House survives",
          not looks_like_description("The Glass House"))
    check("...and The Shard survives", not looks_like_description("The Shard"))
    check("a bare name survives", not looks_like_description("Worth Monument"))

    # --- duplicate title nearby: the Grace Farms shape
    def pin(eid, title, lat, lon):
        return {"id": eid, "title": title, "kind": "single",
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}
    cat = {"tours": [], "linkPins": [
        pin("a", "Grace Farms", 41.196273, -73.512642),
        pin("b", "Grace Farms", 41.196273, -73.512642),
        pin("c", "Rainier Tower", 47.6088172, -122.3343526),
        pin("d", "Centre Pompidou", 48.8607, 2.3522),
        pin("e", "Centre Pompidou", 43.8, 10.5),
        # 🔴 A uniquely-titled pin sitting ON another entry. Without this, the
        # title-match filter could be deleted and every test still passed:
        # every fixture pair happened to share a title already.
        pin("f", "A Totally Different Subject", 47.6088172, -122.3343526),
        # 🔴 Two EMPTY titles on one point, so the empty-title guard is the only
        # thing that can stop a finding.
        pin("g", "", 10.0, 20.0),
        pin("h", "", 10.0, 20.0)]}
    check("🔴 two pins with ONE title on ONE point are caught",
          duplicate_nearby(cat["linkPins"][0], cat))
    check("🔴 an entry never matches ITSELF",
          not duplicate_nearby(cat["linkPins"][2], cat))
    check("the same title FAR away is not flagged — two real places may share a name",
          not duplicate_nearby(cat["linkPins"][3], cat))
    # 🔴 The title must MATCH something, or the coordinate guard is never
    # reached: a unique title exits the loop before any distance is computed.
    check("🔴 an entry with no coordinate is not flagged, even when its title "
          "matches a real entry",
          not duplicate_nearby({"id": "z", "title": "Grace Farms", "stops": []}, cat))
    check("🔴 an entry with no title is not flagged, even beside another "
          "empty title on the same point",
          not duplicate_nearby(cat["linkPins"][6], cat))
    check("🔴 a uniquely-titled pin ON another entry is not flagged",
          not duplicate_nearby(cat["linkPins"][5], cat))

    # ⚠️ Three Rainier Tower pins on ONE coordinate are CORRECT — the owner
    # confirmed all three. So this check must FLAG them and the message must
    # say "if they are different subjects", not "this is wrong".
    r = duplicate_nearby({"id": "x", "title": "Rainier Tower", "kind": "single",
                          "stops": [{"order": 0, "latitude": 47.6088172,
                                     "longitude": -122.3343526}]}, cat)
    check("🔴 a legitimate duplicate is flagged but phrased as a QUESTION",
          r and "if they are different subjects" in r)

    check("findings() gathers every reason",
          len(findings({"id": "q", "title": "A weird church?😱",
                        "stops": [{"order": 0, "latitude": 1.0, "longitude": 2.0}]},
                       cat)) >= 2)
    check("findings() is empty for a clean named pin",
          findings(pin("q", "Worth Monument", 40.7, -74.0), cat) == [])

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{len(ran) - len(fails)}/{len(ran)}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--radius", type=float, default=DUPLICATE_RADIUS_M)
    runstamp.add_out_argument(ap)
    a = ap.parse_args()
    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            doc = json.load(fh)
        n = 0
        for entry in (doc.get("tours") or []) + (doc.get("linkPins") or []):
            for reason in findings(entry, doc, a.radius):
                print(f"  {(entry.get('title') or '')[:44]:44} {reason}")
                n += 1
        print(f"\n{n} finding(s)")
        print("⚠️  A flagged duplicate is a QUESTION, not a verdict — three Rainier")
        print("    Tower pins share one point and all three are correct.")
        return 1 if n else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
