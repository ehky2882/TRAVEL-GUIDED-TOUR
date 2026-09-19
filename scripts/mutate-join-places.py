#!/usr/bin/env python3
"""Break one guard in `join-places.py` at a time; the selftest MUST go red.

🔴 This tool MOVES content. A join drags an entry onto a coordinate and edits
the catalogue in place, so a guard that cannot fail here is not a reporting
bug, it is data loss. Six guards elsewhere this session read as green while
proving nothing.
"""
import os
import subprocess
import sys

SRC = "scripts/join-places.py"
TMP = "scripts/_mutant_join_places.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("🔴 marker: a walk joins by stops[0] instead of order 0",
  '    for stop in stops:\n        if stop.get("order") == 0:\n            return stop\n    return None',
  '    return stops[0]'),
 ("marker: an entry with no stops returns one anyway",
  'if not stops:\n        return None', 'if not stops:\n        return {"latitude": 0, "longitude": 0}'),
 ("🔴 join: the member is NOT moved onto the place",
  'stop["latitude"], stop["longitude"] = lat, lon', 'pass'),
 ("🔴 join: the centroid is left behind",
  'entry["centroidLatitude"], entry["centroidLongitude"] = lat, lon', 'pass'),
 ("join: the id is sorted in rather than appended",
  'place.setdefault("tourIds", []).append(entry["id"])',
  'place.setdefault("tourIds", []).append(entry["id"]); place["tourIds"].sort()'),
 ("join: a walk's other stops are moved too",
  '    stop["latitude"], stop["longitude"] = lat, lon',
  '    for s in entry.get("stops") or []:\n        s["latitude"], s["longitude"] = lat, lon'),
 ("🔴 join: the refusal becomes a different error, not the deliberate one",
  'raise ValueError(f"{entry.get(\'title\')!r} has no stop that draws a pin")',
  'raise TypeError("boom")'),
 ("🔴 candidates: --max-move cannot widen (the bug this found)",
  'near = board.unjoined_places(doc, max_move_m)',
  'near = board.unjoined_places(doc)'),
 ("🔴 candidates: the declined record is not consulted",
  'if fold(entry.get("title")) in refused or fold(place.get("name")) in refused:\n            continue',
  'if False:\n            continue'),
 ("🔴 candidates: proximity alone is enough, both name signals ignored",
  'rows = [r for r in near\n            if id(r[1]) in by_title or caption_names_place(r[1], r[2])]',
  'rows = list(near)'),
 ("🔴 candidates: the TITLE signal is dropped",
  'if id(r[1]) in by_title or caption_names_place(r[1], r[2])]',
  'if caption_names_place(r[1], r[2])]'),
 ("🔴 candidates: the CAPTION signal is dropped",
  'if id(r[1]) in by_title or caption_names_place(r[1], r[2])]',
  'if id(r[1]) in by_title]'),
 ("🔴 declined: the record comes back empty, so nothing is ever refused",
  'for attr in ("DECLINED", "DECLINED_GROUPS", "DECLINED_PAIRS"):',
  'for attr in ():'),
 ("declined: only one of the three lists is read",
  'for attr in ("DECLINED", "DECLINED_GROUPS", "DECLINED_PAIRS"):',
  'for attr in ("DECLINED",):'),
 ("🔴 fold: accents let an entry slip past the DECLINED record",
  'stripped = "".join(c for c in unicodedata.normalize("NFKD", (text or "").lower())\n                       if not unicodedata.combining(c))',
  'stripped = (text or "").lower()'),
]

caught = missed = 0
for name, find, repl in MUTANTS:
    if ORIG.count(find) != 1:
        print(f"  SKIP (anchor {ORIG.count(find)}x) {name}")
        missed += 1
        continue
    open(TMP, "w", encoding="utf-8").write(ORIG.replace(find, repl))
    result = subprocess.run([sys.executable, TMP, "--selftest"],
                            capture_output=True, text=True)
    os.remove(TMP)
    ok = result.returncode != 0
    print(f"  {'caught' if ok else '🔴 MISSED'}  {name}")
    caught += ok
    missed += not ok

print(f"\nMUTATIONS {caught}/{caught + missed} caught")
sys.exit(1 if missed else 0)
