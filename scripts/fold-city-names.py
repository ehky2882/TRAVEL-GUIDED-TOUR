#!/usr/bin/env python3
"""Fold `City (District)` and `City, Region` onto the bare city name.

WHY
---
`city` is the coarse grouping key: it drives the browse screen, the Settings
count, and what "More like this" reasons about. Some entries put the
neighbourhood inside it —

    Tokyo                 237 entries
    Tokyo (Shibuya)         4
    Tokyo (Ginza)           1

— and the app then treats those as three different cities. Someone browsing
Tokyo does not see the Shibuya entries; the city count grows without the
catalogue covering anywhere new. **Tokyo has nineteen such variants, New York
six.** It gets worse with scale, because every batch in a new neighbourhood
mints another near-empty city.

Nothing is lost by folding: the district is already in the coordinate, which is
what drives the map and proximity, and usually in the title. If a district
LABEL is ever wanted, it belongs in its own field rather than overloading the
grouping key.

🔴 THE RULE IS NARROW ON PURPOSE
---------------------------------
Only a **parenthetical or comma suffix** folds, and only onto a bare name that
already exists nearby in the same country. That single restriction is what
keeps genuinely different cities out, without needing a hand-maintained
exception list:

    Tokyo (Shibuya)          -> Tokyo           paren
    Washington, D.C.         -> Washington      comma
    Osoyoos, British Columbia-> Osoyoos         comma

    Miami Beach              NOT folded — a bare prefix, not a suffix pattern
    North Miami Beach        NOT folded
    Osakasayama              NOT folded
    Luxembourg City          NOT folded

⚠️ `Miami`/`Miami Beach` is exactly the pair a looser "starts with" rule would
destroy, and it is a genuinely different city. The audit board REPORTS it,
deliberately; this tool refuses to act on it.
"""

from __future__ import annotations

import argparse
import collections
import importlib.util
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")

NEAR_KM = 30.0

PAREN = re.compile(r"^(.*?)\s*\([^)]*\)\s*$")
COMMA = re.compile(r"^([^,]+),\s*.+$")


def _board():
    spec = importlib.util.spec_from_file_location(
        "_audit_board", os.path.join(HERE, "audit-board.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def bare_form(city):
    """The bare city name a suffixed variant folds onto, or None.

    🔴 Only a SUFFIX in brackets or after a comma. A bare prefix
    (`Miami Beach`) returns None, which is what keeps a different city safe.
    """
    if not city:
        return None
    text = city.strip()
    for pattern in (PAREN, COMMA):
        match = pattern.match(text)
        if match:
            stem = match.group(1).strip()
            if stem and stem != text:
                return stem
    return None


def foldable(doc, near_km=NEAR_KM):
    """(variant, bare, n) for every variant whose bare form really exists."""
    board = _board()
    seen = collections.defaultdict(list)
    for entry in board.entries(doc):
        city = (entry.get("city") or "").strip()
        lat, lon = board.marker(entry)
        if city and lat is not None:
            seen[city].append((lat, lon, entry.get("country")))
    out = []
    for city in sorted(seen):
        stem = bare_form(city)
        if stem is None or stem not in seen:
            continue
        (la, lo, ca), (lb, lob, cb) = seen[city][0], seen[stem][0]
        if ca != cb:
            continue                       # two countries, not one city
        if board.metres(la, lo, lb, lob) > near_km * 1000:
            continue                       # same name, different place
        out.append((city, stem, len(seen[city])))
    return out


def apply_fold(doc, pairs):
    board = _board()
    rename = {variant: stem for variant, stem, _ in pairs}
    changed = 0
    for entry in board.entries(doc):
        city = (entry.get("city") or "").strip()
        if city in rename:
            entry["city"] = rename[city]
            changed += 1
    return changed


def selftest():
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    def pin(eid, city, lat, lon, country="United States"):
        return {"id": eid, "title": eid, "city": city, "country": country,
                "kind": "single",
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}

    check("a parenthetical district folds", bare_form("Tokyo (Shibuya)") == "Tokyo")
    check("a comma region folds", bare_form("Washington, D.C.") == "Washington")
    check("a longer comma tail folds",
          bare_form("Osoyoos, British Columbia") == "Osoyoos")
    check("🔴 a bare PREFIX does not fold — Miami Beach is its own city",
          bare_form("Miami Beach") is None)
    check("🔴 nor does North Miami Beach", bare_form("North Miami Beach") is None)
    check("🔴 nor Osakasayama", bare_form("Osakasayama") is None)
    check("🔴 nor Luxembourg City", bare_form("Luxembourg City") is None)
    check("a plain name folds to nothing", bare_form("Tokyo") is None)
    check("empty is handled", bare_form("") is None and bare_form(None) is None)
    check("a name that is ONLY brackets does not fold to empty",
          bare_form("(Shibuya)") is None)

    doc = {"tours": [], "places": [], "linkPins": [
        pin("a", "Tokyo", 35.6762, 139.6503, "Japan"),
        pin("b", "Tokyo (Shibuya)", 35.6580, 139.7016, "Japan"),
        pin("c", "Miami", 25.7617, -80.1918),
        pin("d", "Miami Beach", 25.7907, -80.1300),
        pin("e", "Springfield, Missouri", 37.2090, -93.2923),
        pin("f", "Paris (Le Marais)", 48.8566, 2.3522, "France")]}
    got = {v: s for v, s, _ in foldable(doc)}
    check("🔴 Tokyo (Shibuya) is foldable", got.get("Tokyo (Shibuya)") == "Tokyo")
    check("🔴 Miami Beach is NOT", "Miami Beach" not in got)
    check("🔴 a comma variant with NO bare form present is not foldable — "
          "there is nothing to fold onto", "Springfield, Missouri" not in got)
    check("🔴 nor a paren variant whose bare form is absent",
          "Paris (Le Marais)" not in got)

    far = {"tours": [], "places": [], "linkPins": [
        pin("a", "Springfield", 39.80, -89.65),
        pin("b", "Springfield, Missouri", 37.21, -93.29)]}
    check("🔴 a same-named city 400 km away is NOT folded", foldable(far) == [])

    # ⚠️ `London` / `London, Ontario` does NOT isolate the country rule: they
    # are 5,900 km apart, so proximity excludes the pair first and the country
    # check never runs. A pair that is CLOSE and cross-border is what tests it.
    abroad = {"tours": [], "places": [], "linkPins": [
        pin("a", "Basel", 47.5596, 7.5886, "Switzerland"),
        pin("b", "Basel, Haut-Rhin", 47.5840, 7.5620, "France")]}
    check("🔴 ONLY the country rule keeps a close cross-border pair apart",
          foldable(abroad) == [])
    check("...and the same pair in ONE country does fold",
          len(foldable({"tours": [], "places": [], "linkPins": [
              pin("a", "Basel", 47.5596, 7.5886, "Switzerland"),
              pin("b", "Basel, Stadt", 47.5840, 7.5620, "Switzerland")]})) == 1)

    n = apply_fold(doc, foldable(doc))
    cities = {e["city"] for e in doc["linkPins"]}
    check("the fold rewrites exactly the variants it reported", n == 1)
    check("🔴 after folding, Tokyo (Shibuya) is gone", "Tokyo (Shibuya)" not in cities)
    check("🔴 and Miami Beach is untouched", "Miami Beach" in cities)

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{len(ran) - len(fails)}/{len(ran)}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            doc = json.load(fh)
        pairs = foldable(doc)
        before = len({(e.get("city") or "").strip()
                      for e in _board().entries(doc) if e.get("city")})
        print(f"{len(pairs)} variant(s) to fold, "
              f"{sum(n for _, _, n in pairs)} entries\n")
        for variant, stem, n in pairs:
            print(f"  {n:3}  {variant:34} -> {stem}")
        if not a.apply:
            print("\nreport only — pass --apply to write")
            return 0
        changed = apply_fold(doc, pairs)
        after = len({(e.get("city") or "").strip()
                     for e in _board().entries(doc) if e.get("city")})
        with open(a.catalog, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print(f"\nrewrote {changed} entries · cities {before} -> {after}")
        print("⚠️  Run `swift scripts/validate-tours.swift` (or the Python mirror).")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
