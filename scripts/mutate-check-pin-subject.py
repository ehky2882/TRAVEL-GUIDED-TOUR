#!/usr/bin/env python3
"""Break one guard in `check-pin-subject.py`; the selftest MUST go red.

🔴 This harness covers the CACHE-COVERAGE guard specifically. A vision verdict
is reached about ONE title and ONE image, and the failure it protects against is
silent in both directions: a stale CONTRADICTS reads exactly like a live finding
(Old Spitalfields Market kept one after the very image that earned it had been
replaced), and a never-asked entry reads as covered because nothing says
otherwise. Either way the report is confidently wrong rather than visibly
incomplete. The sibling failure in `spine-match.py` is in `docs/lessons.md` § 1.
"""
import os
import subprocess
import sys

SRC = "scripts/check-pin-subject.py"
TMP = "scripts/_mutant_check_pin_subject.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("🔴 coverage: a stale record counts as answered, so a dead verdict reads live",
  'elif record.get("digest") != digest(pin):\n            stale.append(pin)',
  'elif False:\n            stale.append(pin)'),
 ("🔴 coverage: a never-asked entry counts as answered",
  'if record is None:\n            never.append(pin)',
  'if False:\n            never.append(pin)'),
 ("🔴 coverage: everything reads as stale, so the report says nothing",
  'elif record.get("digest") != digest(pin):',
  'elif True:'),
 ("coverage: stale and never-asked are merged, losing which is which",
  'never.append(pin)', 'stale.append(pin)'),
 ("🔴 digest: the IMAGE is dropped, so a replaced hero keeps its verdict",
  'pin.get("heroImageURL") or "",', '"",'),
 ("🔴 digest: the TITLE is dropped, so a rename keeps its verdict",
  'payload = json.dumps([pin.get("title") or "",', 'payload = json.dumps(["",'),
 ("digest: the record version is dropped, so a format change is invisible",
  'pin.get("city") or "", RECORD_VERSION],', 'pin.get("city") or ""],'),
 ("coverage: answered is returned empty, hiding that anything was checked",
  'answered.append(pin)', 'pass'),

 # --- the scope the guard reports on; a break here would mask it ----------
 ("🔴 --all stops covering tours, so half the catalogue is silently unasked",
  'def every_entry(catalog):', 'def every_entry(catalog):\n    return [e for e in (catalog.get("linkPins") or []) if e.get("heroImageURL")]\ndef _unused(catalog):'),
 ("an entry with no hero is asked about anyway — there is nothing to look at",
  'if entry.get("heroImageURL"):', 'if True:'),
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
