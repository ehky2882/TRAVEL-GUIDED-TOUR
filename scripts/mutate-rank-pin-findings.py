#!/usr/bin/env python3
"""Break one guard in `rank-pin-findings.py`; the selftest MUST go red.

🔴 WHY THIS TOOL EXISTS

This script decides WHICH of 323 findings a human looks at first, and the
owner's attention is the scarce resource the whole sweep is spending. A guard
that cannot fail here does not produce an error — it produces a queue that is
quietly sorted wrong, and the tell is invisible: every band still has a
plausible number in it, the tool still prints a stamp, and nothing is red.

The specific danger is a mutant that makes everything `same-area`. That looks
like a *clean* catalogue rather than a broken ranker, so it would be believed.

A selftest that passes proves the code works today. Only a sabotage the test
CATCHES proves the test would notice it breaking.
"""
import os
import subprocess
import sys

SRC = "scripts/rank-pin-findings.py"
TMP = "scripts/_mutant_rank_pin.py"
ORIG = open(SRC, encoding="utf-8").read()

# A mutant that provably cannot change the output. Not a test gap: no test
# could catch it, and counting it as a miss would push someone to write a
# test that asserts nothing. Listed so the next reader does not re-file it.
EQUIVALENT = [
 ("fold: dropping the combining-mark filter changes NOTHING — the "
  "`[^a-z0-9 ]` regex already removes combining marks, verified over "
  "Zürich / São Paulo / Málaga / Ōsaka / Reykjavík. The line is "
  "belt-and-braces, and the regex is the guard that actually folds.",
  's = "".join(c for c in s if not unicodedata.combining(c))',
  's = "".join(c for c in s)'),
]

MUTANTS = [
 ("🔴 fold: case is no longer folded",
  'return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()',
  'return re.sub(r"[^a-zA-Z0-9 ]", "", s).strip()'),

 # --- gazetteer(): what the bands are computed against -------------------
 ("gazetteer: a city with no country still enters the map",
  'if city and country:', 'if city or country:'),

 # --- band_of(): the ranking itself --------------------------------------
 ("🔴 band_of: nothing is ever cross-country — the queue looks clean",
  'if t in countries and t != fold(entry_country):', 'if False:'),
 ("🔴 band_of: the entry's OWN country counts as cross-country",
  'if t in countries and t != fold(entry_country):', 'if t in countries:'),
 ("🔴 band_of: a city in ANOTHER country no longer bands cross-country",
  'if t in city_country and fold(entry_country) not in {',
  'if False and t in city_country and fold(entry_country) not in {'),
 ("band_of: nothing is ever cross-city",
  'if t in city_country and t != fold(entry_city):', 'if False:'),
 ("🔴 band_of: the entry's OWN city counts as cross-city",
  'if t in city_country and t != fold(entry_city):', 'if t in city_country:'),
 ("band_of: everything falls through to same-area",
  'return "cross-city", t', 'return "same-area", ""'),
 ("band_of: the answer is never split, so no token ever matches",
  'tokens = [fold(t) for t in re.split(r"[,()]", said or "") if fold(t)]',
  'tokens = [fold(said or "")] if fold(said or "") else []'),
 ("band_of: an empty gate C answer crashes instead of banding",
  'tokens = [fold(t) for t in re.split(r"[,()]", said or "") if fold(t)]',
  'tokens = [fold(t) for t in re.split(r"[,()]", said) if fold(t)]'),

 # --- rank(): what reaches the queue at all ------------------------------
 ("🔴 rank: a CONFIRMS is ranked too — the queue fills with passes",
  'if rec.get("verdict") != "CONTRADICTS":', 'if False:'),
 ("🔴 rank: an owner-ruled finding comes back and is asked again",
  'if fold(title) in ruled_titles:', 'if False:'),
 ("rank: the ruled title is skipped but not counted",
  'skipped += 1', 'pass'),
 ("rank: every finding is treated as ruled, so the queue empties",
  'if fold(title) in ruled_titles:', 'if True:'),
]

# 🔴 CONTROL FIRST. A mutant is "caught" when the selftest goes red -- so a
# source that is broken for ANY reason makes every mutant read as caught and
# the harness reports a perfect score. That happened while writing this file:
# a malformed docstring made it print 14/14 on a file that would not parse.
# An unmutated source whose own selftest does not pass proves nothing.
control = subprocess.run([sys.executable, SRC, "--selftest"],
                         capture_output=True, text=True)
if control.returncode != 0:
    print("🔴 COULD NOT VERIFY — the UNMUTATED source fails its own selftest,")
    print("   so every mutant would read as caught. Fix the source first.\n")
    print(control.stdout[-800:] or control.stderr[-800:])
    sys.exit(2)
print("  control     unmutated source passes its selftest")

for name, _, _ in EQUIVALENT:
    print(f"  equivalent  {name}")

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
