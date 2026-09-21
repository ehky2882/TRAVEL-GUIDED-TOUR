#!/usr/bin/env python3
"""Break one guard in `check-same-name.py`; the selftest MUST go red.

🔴 The failure this file protects against is SILENCE. The tool's whole value is
that agreement is the norm — 158 of 164 groups sit within 100 m — so a mutant
that swallows the outlier, merges two cities' venues into one group, or measures
against a centroid instead of the widest gap does not produce a wrong number. It
produces NO number, and an empty report reads exactly like a clean catalogue.
"""
import os
import subprocess
import sys

SRC = "scripts/check-same-name.py"
TMP = "scripts/_mutant_check_same_name.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- the measurement ----------------------------------------------------
 ("🔴 metres: longitude is not scaled by latitude, inflating every gap",
  '* 111_320.0 * math.cos(math.radians(a[0]))', '* 111_320.0'),
 ("🔴 spread: a CENTROID replaces the widest gap, softening the outlier",
  'return max((metres(a[1], b[1]) for a in members for b in members), default=0.0)',
  'c = (sum(m[1][0] for m in members) / len(members),\n         sum(m[1][1] for m in members) / len(members))\n    return max((metres(m[1], c) for m in members), default=0.0)'),
 ("spread: the MINIMUM gap is used, so any agreeing pair hides the rest",
  'return max((metres(a[1], b[1]) for a in members for b in members), default=0.0)',
  'return min((metres(a[1], b[1]) for a in members for b in members if a is not b), default=0.0)'),

 # --- the grouping -------------------------------------------------------
 ("🔴 groups: the CITY is dropped, so two cities' venues merge into one group",
  'out[(stem, (entry.get("city") or "").strip().lower())].append((entry, at))',
  'out[(stem, "")].append((entry, at))'),
 ("🔴 groups: the raw title replaces the display stem, so a bilingual tail splits a group",
  'stem = display_stem(entry.get("title") or "").strip().lower()',
  'stem = (entry.get("title") or "").strip().lower()'),
 ("🔴 groups: link pins are dropped, so a tour and a pin never pair",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("tours") or [])'),
 ("groups: tours are dropped",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("linkPins") or [])'),
 ("groups: an untitled entry forms a group with every other untitled one",
  'if not stem:\n            continue', 'if False:\n            continue'),

 # --- the report ---------------------------------------------------------
 ("🔴 findings: nothing is ever reported, and an empty report reads as clean",
  'if span <= agree_m:\n            continue', 'if True:\n            continue'),
 ("findings: everything is reported, burying the six in 164",
  'if span <= agree_m:\n            continue', 'if False:\n            continue'),
 # ⚠️ NOT a mutant — recorded here so nobody re-adds it as a gap. Removing the
 # `len(members) < 2` guard is EQUIVALENT: `spread()` over one member is
 # max(metres(m, m)) == 0.0, so the group is dropped by the `span <= agree_m`
 # test on the next line at every threshold, including 0. The guard states
 # intent and skips pointless work; it cannot be made to fail.
 ("🔴 caption: a repeated boilerplate title is never flagged, so a titling "
  "defect reads as a coordinate one",
  'return (text.endswith("…") or len(text) > 45 or text.count(" ") > 7\n            or "#" in text or text.rstrip().endswith(("!", "?")))',
  'return False'),
 ("caption: every title is flagged, so the distinction says nothing",
  'return (text.endswith("…") or len(text) > 45 or text.count(" ") > 7\n            or "#" in text or text.rstrip().endswith(("!", "?")))',
  'return True'),
 ("caption: an empty title is called a caption",
  'if not text:\n        return False', 'if not text:\n        return True'),
 ("marker: a stop numbered other than 0 is dropped",
  'return (stops[0]["latitude"], stops[0]["longitude"])', 'return None'),
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
