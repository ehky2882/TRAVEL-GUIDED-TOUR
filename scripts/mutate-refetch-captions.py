#!/usr/bin/env python3
"""Break one guard in `refetch-captions.py`; the selftest MUST go red.

🔴 This script REWRITES text a reader will see, from a source we do not
control, so its failure mode is not a wrong number — it is a caption replaced
by somebody else's words. The prefix guard is the only thing standing between
"the same caption, now complete" and "whatever that URL serves today", and a
mutant that weakens it produces MORE recoveries, not fewer. A broken run would
look like a better one.
"""
import os
import subprocess
import sys

SRC = "scripts/refetch-captions.py"
TMP = "scripts/_mutant_refetch_captions.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- the prefix guard ---------------------------------------------------
 ("🔴 guard: any fetched text is accepted, so a re-used URL overwrites a caption",
  'if not got.startswith(normalise(stored)):\n        return False, "mismatch"', ''),
 ("🔴 guard: the prefix test runs on RAW text, so every caption with a line "
  "break is rejected — the whole of Instagram",
  'if not got.startswith(normalise(stored)):', 'if not got.startswith(stored):'),
 ("guard: a substring anywhere counts, not a prefix",
  'if not got.startswith(normalise(stored)):', 'if normalise(stored) not in got:'),
 ("🔴 guard: a SHORTER caption is written, throwing away what we already had",
  'if len(got) <= len(stored):\n        return False, "no-longer"', ''),
 ("🔴 guard: an empty fetch reads as success, erasing the caption",
  'if not got:\n        return False, "empty"', ''),

 # --- normalisation ------------------------------------------------------
 ("🔴 normalise: whitespace is no longer collapsed, so it stops matching what "
  "the pipeline stores",
  'return " ".join((text or "").split())', 'return text or ""'),
 ("normalise: None crashes instead of reading as empty",
  'return " ".join((text or "").split())', 'return " ".join(text.split())'),

 # --- selection ----------------------------------------------------------
 ("🔴 selection: entries SHORTER than the cut are swept in too, so untruncated "
  "captions get rewritten",
  'if len(cap) == cut and url:', 'if len(cap) <= cut and url:'),
 ("selection: an entry with no source URL is attempted anyway",
  'if len(cap) == cut and url:', 'if len(cap) == cut:'),
 ("🔴 selection: tours are dropped, so only pins are ever recovered",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("linkPins") or [])'),
 ("selection: link pins are dropped",
  'return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])',
  'return list(catalog.get("tours") or [])'),
 ("selection: an entry with no stops crashes the run",
  'if not stops:\n            continue', 'if False:\n            continue'),
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
