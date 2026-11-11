#!/usr/bin/env python3
"""Break one guard in `triage-spine.py`; the selftest MUST go red.

🔴 The dangerous failure is a CONFIDENT WRONG VERDICT. This tool decides whether
to move a coordinate, and a coordinate is the defect CLAUDE.md calls invisible
to every other check: the validator passes, CI compiles, every URL 200s, and the
tour simply never fires. A mutant that inverts a verdict, or that lets an
undecidable row read as decided, would move a CORRECT pin onto a different place
of the same name — turning a working tour into a silently broken one.
"""
import os
import subprocess
import sys

SRC = "scripts/triage-spine.py"
TMP = "scripts/_mutant_triage_spine.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- verdict(): the decision itself ------------------------------------
 ("🔴 verdict: the two sides are swapped, inverting every answer",
  'if theirs_m > ours_m * ratio:\n        return "WIKIDATA-ELSEWHERE"',
  'if ours_m > theirs_m * ratio:\n        return "WIKIDATA-ELSEWHERE"'),
 ("🔴 verdict: OURS-WRONG is returned whenever the sides differ at all",
  'if ours_m > theirs_m * ratio:', 'if ours_m > theirs_m:'),
 ("🔴 verdict: a missing cluster no longer forces UNDECIDED",
  'if ours_m is None or theirs_m is None:\n        return "UNDECIDED"',
  'if False:\n        return "UNDECIDED"'),
 ("verdict: the ratio is dropped, so near-ties decide",
  'ratio=RATIO', 'ratio=1.0'),
 ("verdict: nothing is ever WIKIDATA-ELSEWHERE",
  'return "WIKIDATA-ELSEWHERE"      # their match is a different place',
  'return "UNDECIDED"      # their match is a different place'),

 # --- the cluster: MEDIAN is load-bearing -------------------------------
 ("🔴 cluster: the mean replaces the median, so one outlier drags the city",
  'clat = statistics.median(p[0] for p in pts)\n            clon = statistics.median(p[1] for p in pts)',
  'clat = statistics.mean(p[0] for p in pts)\n            clon = statistics.mean(p[1] for p in pts)'),
 ("🔴 cluster: the entry is measured against ITSELF",
  'if i != key.upper()]', ']'),
 ("cluster: the minimum size is dropped, so one neighbour decides a city",
  'if len(pts) >= min_cluster:', 'if pts:'),

 # --- extent() and same_municipality(): the two FACT signals -----------
 ("🔴 extent: nothing is ever extended, so a tram system is a finding",
  'return "EXTENDED" if any(w in d for w in EXTENDED_WORDS) else "POINT"',
  'return "POINT"'),
 ("🔴 extent: everything is extended, so a skyscraper stops being a finding",
  'return "EXTENDED" if any(w in d for w in EXTENDED_WORDS) else "POINT"',
  'return "EXTENDED"'),
 ("extent: the word list is gutted",
  'EXTENDED_WORDS = (', 'EXTENDED_WORDS = ("zzzznope",) or ('),
 ("🔴 same_municipality: accents break the comparison again",
  't = "".join(c for c in t if not unicodedata.combining(c))\n        return " ".join(re.sub(r"[^a-z0-9 ]", " ", t).split())',
  'return " ".join(re.sub(r"[^a-z0-9 ]", " ", t).split())'),
 ("🔴 same_municipality: every city compares equal",
  'return key(our_city) == key(wd_admin)', 'return True'),
 ("same_municipality: a missing side claims a match",
  'if not our_city or not wd_admin:\n        return None',
  'if False:\n        return None'),
 ("🔴 triage: a different municipality no longer overrides the distance",
  'if row["same_city"] is False:\n                row["verdict"] = "WIKIDATA-ELSEWHERE"',
  'if False:\n                row["verdict"] = "WIKIDATA-ELSEWHERE"'),
 ("🔴 triage: an extended feature is left in the queue",
  'elif row["extent"] == "EXTENDED":\n                row["verdict"] = "EXTENDED-FEATURE"',
  'elif False:\n                row["verdict"] = "EXTENDED-FEATURE"'),
 ("triage: the overrides fire even on a DECIDED verdict, burying OURS-WRONG",
  'if row["verdict"] == "UNDECIDED":', 'if True:'),

 # --- scope --------------------------------------------------------------
 ("🔴 triage: agreeing rows become findings too",
  'if best["distance_m"] <= agree_m:\n            continue',
  'if False:\n            continue'),
 ("triage: the FURTHEST candidate is picked instead of the nearest",
  'best = min(cands, key=lambda c: c["distance_m"])',
  'best = max(cands, key=lambda c: c["distance_m"])'),
 ("triage: an entry with no candidates is still reported",
  'if not cands:\n            continue', 'cands = cands or [{"distance_m": 9e9, "label": "", "lat": 0, "lon": 0, "qid": None}]\n        if False:\n            continue'),
 ("metres: longitude is not scaled by latitude",
  '* 111_320.0 * math.cos(math.radians(lat1))', '* 111_320.0'),
]

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
