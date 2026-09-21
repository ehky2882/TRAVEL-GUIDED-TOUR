#!/usr/bin/env python3
"""Break one guard in `spine-match.py`; the selftest MUST go red.

🔴 The failure this file exists for is a STALE NUMBER REPORTED AS CURRENT. On
2026-09-21 the audit said Belgrade Tower sat 2,329 m from its subject for hours
after the coordinate had been moved onto Wikidata's own point — a 0 m agreement.
The cache had been built against the old point and nothing compared it to the
catalogue we actually hold.

That reads as a nuisance and is not. It cuts both ways, and the second way is
the dangerous one: a coordinate moved to the WRONG place keeps reporting its OLD
distance, so the one check that exists to police such a move is blind to exactly
the edit it was built for, and CI stays green. A mutant that lets a moved entry
read as CONFIRMS, or that keeps a distance on a row the tool cannot stand behind,
puts that blindness straight back.
"""
import os
import subprocess
import sys

SRC = "scripts/spine-match.py"
TMP = "scripts/_mutant_spine_match.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- the staleness guard ------------------------------------------------
 ("🔴 stale: the digest is never compared, so a moved entry reads as CONFIRMS",
  'return ask_digest(entry.get("title"), at,\n                      record.get("bound_km", 100.0)) != record.get("digest")',
  'return False'),
 ("🔴 stale: the classifier ignores the guard entirely",
  'if is_stale(entry, at, record):', 'if False:'),
 ("🔴 stale: the LIVE marker is ignored and the cached point re-used, which is "
  "the original bug exactly",
  'return ask_digest(entry.get("title"), at,',
  'return ask_digest(entry.get("title"), tuple(record.get("at") or at),'),
 ("🔴 stale: the title is dropped, so a rename stops being detected",
  'return ask_digest(entry.get("title"), at,',
  'return ask_digest("", at,'),
 ("🔴 stale: a stale row is handed the cached distance after all",
  'out.append({"entry": entry, "band": "STALE", "best": None,\n                        "named": False})',
  'out.append({"entry": entry, "band": "STALE",\n                        "best": best_candidate(entry, record.get("candidates") or []),\n                        "named": False})'),
 ("stale: everything is stale, so the audit can never say anything",
  'record.get("bound_km", 100.0)) != record.get("digest")',
  'record.get("bound_km", 100.0)) != "never"'),
 ("🔴 stale: the run still exits 0 with entries it could not speak for",
  'if counts.get("STALE"):\n        return 2', 'if False:\n        return 2'),
 ("🔴 exit: STALE is demoted to a finding, so CI reads it as reviewable",
  'if counts.get("STALE"):\n        return 2', 'if counts.get("STALE"):\n        return 1'),
 ("🔴 exit: findings outrank the could-not-verify codes",
  'if counts.get("STALE"):\n        return 2\n    if counts.get("NOT-ASKED"):\n        return 2\n    if counts.get("DISAGREES"):\n        return 1',
  'if counts.get("DISAGREES"):\n        return 1\n    if counts.get("STALE"):\n        return 2\n    if counts.get("NOT-ASKED"):\n        return 2'),
 ("🔴 stale rows are counted as covered, inflating the routing figure",
  'return [r for r in rows if r["band"] not in ("NOT-ASKED", "STALE")]',
  'return [r for r in rows if r["band"] != "NOT-ASKED"]'),

 # --- the bands the guard sits beside; a break here would mask it ---------
 ("🔴 band: the disagree floor is raised past a known real error",
  'DISAGREE_M = 250.0', 'DISAGREE_M = 6000.0'),
 ("🔴 band: everything at any distance CONFIRMS",
  'if distance_m <= CONFIRM_M:', 'if True:'),
 ("🔴 band: an extended site becomes a finding again",
  'related=related, extended=extended', 'related=related, extended=False'),
 ("🔴 band: a match beyond MAX_ERROR_M is asserted rather than dropped",
  'if distance_m > MAX_ERROR_M:', 'if False:'),
 ("🔴 classify: an unrelated distant label is asserted as a finding",
  'related=related, extended=extended', 'related=True, extended=extended'),
 ("classify: a label is never treated as related, so every finding softens",
  'related = bool(best) and label_related(entry, best)',
  'related = False'),
 ("🔴 classify: an entry absent from the cache reads as agreeing",
  'if record is None:', 'if False:'),
 ("🔴 marker: a stop numbered other than 0 is silently dropped",
  'return (stops[0]["latitude"], stops[0]["longitude"])', 'return None'),
 ("entries: link pins are not audited",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("tours") or [])'),
]

# 🔴 The control comes FIRST. A harness once printed 14/14 against a source file
# that would not even parse: every mutant "failed", so every mutant read caught.
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
