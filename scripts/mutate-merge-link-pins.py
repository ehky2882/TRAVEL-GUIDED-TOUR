#!/usr/bin/env python3
"""Break the title gate inside `merge-link-pins.py`; the selftest MUST go red.

🔴 This gate REFUSES merges. Two opposite failures both end with it switched
off: one that stops refusing lets the next Torre Velasca through silently, and
one that refuses legitimate names gets disabled by the first person it blocks.
"""
import os
import subprocess
import sys

SRC = "scripts/merge-link-pins.py"
TMP = "scripts/_mutant_merge_link_pins.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("🔴 gate: a caption title is no longer refused",
  'for rule in (gate.looks_like_caption, gate.looks_like_description):',
  'for rule in ():'),
 ("gate: only the caption rule runs, descriptions pass",
  'for rule in (gate.looks_like_caption, gate.looks_like_description):',
  'for rule in (gate.looks_like_caption,):'),
 ("🔴 gate: --allow-unverifiable-title is ignored, so real names get blocked",
  'if allow_unverifiable:', 'if False:'),
 ("🔴 gate: EVERY title is allowed, as if the flag were always on",
  'if allow_unverifiable:', 'if True:'),
 ("gate: the allowed warning stops naming the flag",
  '(allowed by --allow-unverifiable-title)', '(allowed)'),
 ("🔴 gate: a duplicate REFUSES instead of warning — blocks 3 real Rainier pins",
  'warnings.append(f"{where}: {near}")', 'problems.append(f"{where}: {near}")'),
 ("gate: the duplicate check never runs",
  'near = gate.duplicate_nearby(pin, catalog)', 'near = ""'),
 ("🔴 vision: an unfetchable hero reads as CLEAN instead of UNVERIFIED",
  'out.append(f"{where}: hero not fetchable yet ({type(exc).__name__}) "\n                       f"— UNVERIFIED, not clean. Re-run after the image is live")',
  'pass'),
 ("🔴 vision: a pin with NO hero is silently skipped",
  'out.append(f"{where}: no hero image — the picture cannot be asked")',
  'pass'),
 ("vision: the unverified message drops its re-run instruction",
  'f"— UNVERIFIED, not clean. Re-run after the image is live")',
  'f"— UNVERIFIED, not clean.")'),
 ("gate: the refusal loses the Torre Velasca reference, so the reason is opaque",
  'A title nothing can verify is how Torre ', 'Bad title. '),
]

caught = missed = 0
for name, find, repl in MUTANTS:
    if ORIG.count(find) != 1:
        print(f"  SKIP (anchor {ORIG.count(find)}x) {name}"); missed += 1; continue
    open(TMP, "w", encoding="utf-8").write(ORIG.replace(find, repl))
    r = subprocess.run([sys.executable, TMP, "--selftest"], capture_output=True, text=True)
    os.remove(TMP)
    ok = r.returncode != 0
    print(f"  {'caught' if ok else '🔴 MISSED'}  {name}")
    caught += ok; missed += not ok

print(f"\nMUTATIONS {caught}/{caught + missed} caught")
sys.exit(1 if missed else 0)
