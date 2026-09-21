#!/usr/bin/env python3
"""Break one guard in `check-city-outliers.py`; the selftest MUST go red.

🔴 Every other check here is a LOOKUP — it asks a gazetteer where a name is and
compares. This one asks nothing, which is exactly why its guards cannot be
eyeballed: it computes a centre, a scale and a threshold from the catalogue
itself, and each of those three can be broken in a way that produces no error,
no exception and **no finding**. An outlier check that silently flags nothing
reads precisely like a clean catalogue.

The three that matter, and the failure each was chosen against:

* **the MEDIAN** — a mean centre is dragged toward the very entry being hunted,
  and with two bad entries in the same place it hides both;
* **the SELF EXCLUSION** — an entry voting on its own centre pulls the centre
  onto itself;
* **the PER-CITY SCALE** — a flat threshold flags every sprawling city wholesale
  (Hong Kong's Lantau entries are 23-31 km out and all correct), and burying one
  real finding in eighty is the same as not finding it.
"""
import os
import subprocess
import sys

SRC = "scripts/check-city-outliers.py"
TMP = "scripts/_mutant_check_city_outliers.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- the measurement ----------------------------------------------------
 ("🔴 metres: longitude is not scaled by latitude, inflating every gap",
  '* 111_320.0 * math.cos(math.radians(a[0]))', '* 111_320.0'),

 # --- the centre ---------------------------------------------------------
 ("🔴 centre: a MEAN replaces the median, so the outlier drags the centre "
  "toward itself",
  'centre = (statistics.median(p[0] for p in others),\n                      statistics.median(p[1] for p in others))',
  'centre = (sum(p[0] for p in others) / len(others),\n                      sum(p[1] for p in others) / len(others))'),
 ("🔴 centre: an entry votes on its own centre",
  'others = [p for e, p in members if e["id"] != entry["id"]]',
  'others = [p for e, p in members]'),

 # --- the scale ----------------------------------------------------------
 ("🔴 scale: a MEAN spread, which one far member inflates until nothing clears it",
  'spread = statistics.median(metres(p, centre) for p in others)',
  'spread = sum(metres(p, centre) for p in others) / len(others)'),
 ("🔴 scale: the per-city spread is ignored, so a sprawling city is flagged wholesale",
  'if spread > 0 and gap > max(floor_m, spread_x * spread)',
  'if spread > 0 and gap > floor_m'),
 ("scale: the floor is ignored, so a tight city flags its own next street",
  'if spread > 0 and gap > max(floor_m, spread_x * spread)',
  'if spread > 0 and gap > spread_x * spread'),
 ("🔴 scale: max becomes min, so the looser of the two thresholds never applies",
  'gap > max(floor_m, spread_x * spread)', 'gap > min(floor_m, spread_x * spread)'),
 ("scale: a city standing on one point is measured anyway, against the floor alone",
  'if spread > 0 and gap >', 'if gap >'),

 # --- the population -----------------------------------------------------
 ("🔴 population: link pins are dropped, and they are 80% of the catalogue",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("linkPins") or [])'),
 ("🔴 population: tours are dropped, so an Atlas coordinate is never questioned",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("tours") or [])'),
 ("population: the city is assumed rather than read, merging every city into one",
  'city = (entry.get("city") or "").strip()', 'city = "C"'),
 ("population: an entry's own stop is not read, so nothing has a coordinate",
  'return (stops[0]["latitude"], stops[0]["longitude"]) if stops else None',
  'return None'),
 # ⚠️ The `min_others` rule is written TWICE, and neither copy can be broken on
 # its own — see EQUIVALENT below. Only removing BOTH is a real mutant, so this
 # one is the only entry here that makes two edits at once.
 ("🔴 population: a city of three entries is allowed to have an opinion", [
  ('if city in homonym_cities or len(members) <= min_others:\n            continue',
   'if city in homonym_cities:\n            continue'),
  ('if len(others) < min_others:\n                continue',
   'if False:\n                continue')]),

 # --- the homonym hold-out -----------------------------------------------
 ("🔴 homonyms: two cities sharing a name are measured as one, making every "
  "member of the smaller one an outlier",
  'homonym_cities = {r["city"] for r in homonyms(catalog)}', 'homonym_cities = set()'),
 ("🔴 homonyms: the CLOSEST pair decides the span, so seven entries in Puerto "
  "Rico hide the one in the Philippines",
  'span = max(metres(a[1], b[1]) for a in members for b in members)',
  'span = min(metres(a[1], b[1]) for a in members for b in members if a is not b)'),
 ("homonyms: every multi-member city is called a homonym, holding the whole "
  "catalogue out",
  'if span < span_m:\n            continue', 'if False:\n            continue'),
 ("homonyms: nothing is ever a homonym",
  'if span < span_m:\n            continue', 'if True:\n            continue'),
]

# The second half of the min_others pair, mutated alone, is equivalent — proven
# above. It is asserted here rather than trusted, so a later edit that makes the
# two guards differ cannot pass unnoticed.
# 🔴 PROVEN EQUIVALENT, not merely uncaught. `others` is `members` minus the one
# being scored, so `len(members) <= min_others` and `len(others) < min_others`
# are the SAME predicate written twice; whichever copy survives still skips the
# city. Each is asserted here rather than trusted, so a later edit that makes the
# two differ cannot slip through as "equivalent".
EQUIVALENT = [
 ("the inner min_others guard, alone — implied by the outer one",
  [('if len(others) < min_others:\n                continue',
    'if False:\n                continue')]),
 ("the outer min_others guard, alone — implied by the inner one",
  [('if city in homonym_cities or len(members) <= min_others:\n            continue',
    'if city in homonym_cities:\n            continue')]),
]

# 🔴 Control first. A harness once printed 14/14 against a file that would not
# even parse: every mutant "failed", so every mutant read as caught.
control = subprocess.run([sys.executable, SRC, "--selftest"],
                         capture_output=True, text=True)
if control.returncode != 0:
    print("🔴 COULD NOT VERIFY — the UNMUTATED source fails its own selftest,")
    print("   so every mutant would read as caught. Fix the source first.\n")
    print(control.stdout[-800:] or control.stderr[-800:])
    sys.exit(2)
print("  control     unmutated source passes its selftest")


def run(edits):
    """Apply every edit, or none: a mutant that only half-applied would be a
    different mutant than the one named, and would report under its name."""
    text = ORIG
    for find, repl in edits:
        if text.count(find) != 1:
            return None
        text = text.replace(find, repl)
    open(TMP, "w", encoding="utf-8").write(text)
    result = subprocess.run([sys.executable, TMP, "--selftest"],
                            capture_output=True, text=True)
    os.remove(TMP)
    return result.returncode != 0


def edits_of(mutant):
    """Most mutants are one (find, repl) pair; a few need several."""
    body = mutant[1:]
    return body[0] if len(body) == 1 and isinstance(body[0], list) else [tuple(body)]


caught = missed = 0
for mutant in MUTANTS:
    name = mutant[0]
    red = run(edits_of(mutant))
    if red is None:
        print(f"  SKIP (anchor not unique) {name}")
        missed += 1
        continue
    print(f"  {'caught' if red else '🔴 MISSED'}  {name}")
    caught += red
    missed += not red

for name, edits in EQUIVALENT:
    red = run(edits)
    if red is None:
        print(f"  SKIP (anchor not unique) {name}")
        missed += 1
    elif red:
        print(f"  🔴 NOT EQUIVALENT after all — {name}")
        missed += 1
    else:
        print(f"  equiv   {name}")

print(f"\nMUTATIONS {caught}/{caught + missed} caught"
      f" · {len(EQUIVALENT)} proven equivalent")
sys.exit(1 if missed else 0)
