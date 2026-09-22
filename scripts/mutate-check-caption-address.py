#!/usr/bin/env python3
"""Break one guard in `check-caption-address.py`; the selftest MUST go red.

🔴 This check has two ways of failing and they are not symmetric. Made too
LOOSE it floods — a city name matching inside ordinary words, or a city
mentioned in prose rather than at the sign-off, turns hundreds of correct pins
into findings and the real ones are never read. Made too TIGHT it goes silent,
and silence is indistinguishable from a clean catalogue.

⚠️ And the compatibility groups are the load-bearing part in practice: without
them every Brooklyn pin whose caption says "NYC" is a finding, which is most
of them.
"""
import os
import subprocess
import sys

SRC = "scripts/check-caption-address.py"
TMP = "scripts/_mutant_check_caption_address.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- where the location is read from ------------------------------------
 ("🔴 tail: the FIRST marker wins, so an opening marker makes the whole "
  "caption's prose count as the location",
  'return caption.split(MARKER)[-1]', 'return caption.split(MARKER)[1]'),
 ("🔴 tail: the whole caption is searched, so a city mentioned in passing "
  "reads as where the creator was",
  'if MARKER not in (caption or ""):\n        return ""\n    return caption.split(MARKER)[-1]',
  'return caption or ""'),
 ("tail: a caption with no marker returns everything instead of nothing",
  'if MARKER not in (caption or ""):\n        return ""', 'if False:\n        return ""'),

 # --- matching -----------------------------------------------------------
 ("🔴 matching: a city name inside a longer word counts, so 'parisian' is Paris",
  'if re.search(r"(?<![a-z0-9])" + re.escape(key) + r"(?![a-z0-9])", folded):',
  'if key in folded:'),
 ("matching: accents and case stop being folded",
  'return "".join(ch for ch in stripped if not unicodedata.combining(ch)).strip().lower()',
  'return (text or "").strip()'),
 ("🔴 gazetteer: short city names are admitted, and they match inside words",
  'if len(fold(city)) >= 4:', 'if city:'),

 # --- the compatibility groups -------------------------------------------
 ("🔴 groups: every NYC borough now disagrees with a caption saying New York",
  'return any(fa in group and fb in group for group in SAME_PLACE)', 'return False'),
 ("groups: everything is compatible with everything, so nothing is ever flagged",
  'return any(fa in group and fb in group for group in SAME_PLACE)', 'return True'),
 ("groups: an exact match stops counting",
  'if fa == fb:\n        return True', ''),

 # --- the verdict --------------------------------------------------------
 ("🔴 verdict: ANY named city being incompatible flags it, so a caption naming "
  "its own city AND another is a finding",
  'if any(compatible(city, n) for n in named):\n            continue',
  'if all(compatible(city, n) for n in named):\n            continue'),
 ("verdict: nothing is ever reported, and an empty report reads as clean",
  'if distant:\n            found.append', 'if False:\n            found.append'),
 ("verdict: everything is reported",
  'if distant:\n            found.append', 'if True:\n            found.append'),

 ("🔴 venue-name guard: a city word in the entry's own TITLE counts as a "
  "location claim again, and 'Venice Leather' becomes a finding",
  'named = [n for n in named\n                 if not re.search(r"(?<![a-z0-9])" + re.escape(fold(n)) + r"(?![a-z0-9])",\n                                  title)]',
  'named = list(named)'),
 ("🔴 distance: a neighbourhood counts as a different city again",
  'distant = [n for n in named if far_apart(city, n, centres)]',
  'distant = list(named)'),

 # --- the population -----------------------------------------------------
 ("🔴 population: tours are dropped, so an Atlas caption is never checked",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("linkPins") or [])'),
 ("population: link pins are dropped",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("tours") or [])'),
 ("population: an entry with no city is checked anyway",
  'city = (e.get("city") or "").strip()\n        if not stops or not city:\n            continue\n        text = tail',
  'city = (e.get("city") or "").strip()\n        if not stops:\n            continue\n        text = tail'),
]

# 🔴 Control first. A harness once printed 14/14 against a file that would not
# even parse: every mutant "failed", so every mutant read as caught.
control = subprocess.run([sys.executable, SRC, "--selftest"], capture_output=True, text=True)
if control.returncode != 0:
    print("🔴 COULD NOT VERIFY — the UNMUTATED source fails its own selftest,")
    print("   so every mutant would read as caught. Fix the source first.\n")
    print(control.stdout[-800:] or control.stderr[-800:])
    sys.exit(2)
print("  control     unmutated source passes its selftest")

caught = missed = 0
for name, find, repl in MUTANTS:
    if ORIG.count(find) != 1:
        print(f"  SKIP (anchor {ORIG.count(find)}x) {name}")
        missed += 1
        continue
    open(TMP, "w", encoding="utf-8").write(ORIG.replace(find, repl))
    result = subprocess.run([sys.executable, TMP, "--selftest"], capture_output=True, text=True)
    os.remove(TMP)
    red = result.returncode != 0
    print(f"  {'caught' if red else '🔴 MISSED'}  {name}")
    caught += red
    missed += not red

print(f"\nMUTATIONS {caught}/{caught + missed} caught")
sys.exit(1 if missed else 0)
