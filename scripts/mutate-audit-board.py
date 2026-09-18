#!/usr/bin/env python3
"""Break one guard in `audit-board.py` at a time; the selftest MUST go red.

🔴 Five guards this session read as caught while proving nothing — a mutant
saved by equality, a prompt asserted instead of the request body, two no-op
mutations of my own making. A green selftest is not evidence. This is.

Run from the repo root:  python3 scripts/mutate-audit-board.py
A mutant whose anchor no longer matches is a SKIP and fails the run.
"""
import os
import subprocess
import sys

SRC = "scripts/audit-board.py"
TMP = "scripts/_mutant_audit_board.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("fold: accents are not stripped",
  'stripped = "".join(c for c in unicodedata.normalize("NFKD", (text or "").lower())\n                       if not unicodedata.combining(c))',
  'stripped = (text or "").lower()'),
 ("fold: punctuation survives",
  'return re.sub(r"[^a-z0-9]", "", stripped)', 'return stripped'),
 ("join: members of the place are reported too",
  'if entry["id"].upper() in claimed:\n            continue', 'if False:\n            continue'),
 ("join: the radius is ignored",
  'if gap <= radius_m:', 'if True:'),
 ("join: the id comparison is case-sensitive",
  'claimed = {t.upper() for p in (doc.get("places") or [])',
  'claimed = {t for p in (doc.get("places") or [])'),
 ("name: the board's one-argument call silently returns nothing",
  'if rows is None:\n        rows = unjoined_places(doc)', 'if rows is None:\n        rows = []'),
 ("name: any nearby entry counts as the same name",
  'if fold(entry.get("title")) and fold(entry.get("title")) == fold(place.get("name")):',
  'if True:'),
 ("name: an empty title matches an empty place name",
  'if fold(entry.get("title")) and fold(entry.get("title")) == fold(place.get("name")):',
  'if fold(entry.get("title")) == fold(place.get("name")):'),
 ("city: the prefix rule is dropped, so any two names pair",
  'if not (fa.startswith(fb) or fb.startswith(fa)):\n                continue',
  'if False:\n                continue'),
 ("🔴 city: proximity is not required (York == New York)",
  'if metres(la, loa, lb, lob) <= near_km * 1000:', 'if True:'),
 ("city: the country is not required to match",
  'if ca != cb:\n                continue', 'if False:\n                continue'),
 ("🔴 city: accent variants are skipped instead of reported",
  'if not fa or not fb:\n                continue',
  'if not fa or not fb or fa == fb:\n                continue'),
 ("🔴 hero: one post pinned to many venues is reported as a defect",
  'if len(sources) == 1 and None not in sources:\n            continue',
  'if False:\n            continue'),
 ("hero: a hero shared inside one city is reported",
  'if len({fold(e.get("city")) for e in group}) > 1:', 'if True:'),
 ("board: a class with no check is dropped from the board",
  'if fn is None:\n            count = "—"', 'if fn is None:\n            continue'),
 ("🔴 board: a check that raises reports 0 instead of ERR",
  'count = f"ERR:{type(exc).__name__}"', 'count = "0"'),
 ("board: a row loses its meaning line",
  'rows.append((name, tool, where, count, means))',
  'rows.append((name, tool, where, count, ""))'),
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
