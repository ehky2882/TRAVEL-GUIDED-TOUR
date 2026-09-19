#!/usr/bin/env python3
"""Break one guard in `source-hero-image.py`; the selftest MUST go red.

🔴 The two guards here decide what gets PUBLISHED. A licence filter that
cannot fail ships CC BY-SA imagery the app has no way to credit; a size filter
that cannot fail ships an upscaled, soft hero. Neither failure is visible in
the result — the image simply appears, and looks fine.
"""
import os
import subprocess
import sys

SRC = "scripts/source-hero-image.py"
TMP = "scripts/_mutant_source_hero.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("🔴 licence: substring matching lets cc-by-sa-pd-mark through",
  'return (license_code or "").strip().lower() in PD_CODES',
  'return any(c in (license_code or "").lower() for c in PD_CODES)'),
 ("🔴 licence: CC BY-SA is accepted",
  'PD_CODES = {"pd", "cc0"}', 'PD_CODES = {"pd", "cc0", "cc-by-sa-4.0", "cc-by-3.0"}'),
 ("licence: an absent licence passes",
  'return (license_code or "").strip().lower() in PD_CODES',
  'return (license_code or "pd").strip().lower() in PD_CODES'),
 ("licence: whitespace is not stripped",
  '(license_code or "").strip().lower()', '(license_code or "").lower()'),
 ("🔴 size: the short side may upscale",
  'return min(width, height) >= MIN_SHORT and max(width, height) >= MIN_LONG',
  'return max(width, height) >= MIN_LONG'),
 ("🔴 size: the long side may upscale",
  'return min(width, height) >= MIN_SHORT and max(width, height) >= MIN_LONG',
  'return min(width, height) >= MIN_SHORT'),
 ("size: missing dimensions pass",
  'if not width or not height:\n        return False',
  'if not width or not height:\n        return True'),
 ("size: the thresholds are halved",
  'MIN_SHORT, MIN_LONG = 900, 1200', 'MIN_SHORT, MIN_LONG = 450, 600'),
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
