#!/usr/bin/env python3
"""Break one guard in `recover-pin-title.py`; the selftest MUST go red.

🔴 The dangerous failure here is not a crash — it is a PLAUSIBLE WRONG TITLE.
This tool reads a creator's 📍 marker and offers it as a venue name. If the
ADDRESS guard stops working, a postal address becomes a proposed title, and an
address reads far more authoritative than the caption it replaced while being
exactly as unverifiable. A human skimming a review list would accept it.

The second danger is scope: a mutant that lets the tool touch entries whose
titles are already FINE would quietly rewrite good names.
"""
import os
import subprocess
import sys

SRC = "scripts/recover-pin-title.py"
TMP = "scripts/_mutant_recover_title.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 # --- marker(): the input to everything else --------------------------
 ("marker: a hashtag no longer ends the segment",
  'r"📍\\s*([^\\n#]{1,80})"', 'r"📍\\s*([^\\n]{1,80})"'),
 ("marker: a newline no longer ends the segment",
  'r"📍\\s*([^\\n#]{1,80})"', 'r"📍\\s*([^#]{1,80})"'),
 ("marker: nothing is ever found",
  'm = re.search(r"📍\\s*([^\\n#]{1,80})", text or "")', 'm = None'),

 # --- classify(): 🔴 the address guard is the whole safety story ------
 ("🔴 classify: the ADDRESS guard is gone — a postcode becomes a title",
  'if any(p.search(seg) for p in ADDRESS_TELLS) or LOCATION_WORDS.search(seg):',
  'if False:'),
 ("🔴 classify: only the Japanese postcode is checked",
  'ADDRESS_TELLS = (', 'ADDRESS_TELLS = (re.compile(r"(?!x)x"),) or ('),
 # The romaji-address tells, added after three addresses were proposed as
 # venue names. Each must be provably load-bearing on its own.
 ("🔴 classify: the romaji 'N-N Placecho' address tell is dropped",
  're.compile(r"\\b\\d{1,4}-\\d{1,4}\\s+\\w+", re.U),', ''),
 ("🔴 classify: the Ward/ku tell is dropped",
  're.compile(r"\\b(Ward|ku|Chuo|Shi)\\b,", re.I),', ''),
 ("🔴 classify: a REGION is treated as a venue",
  're.compile(r"\\b(Region|Province|Prefecture|County|District)\\b,", re.I),', ''),
 ("classify: 'Where:' no longer marks a location",
  'or LOCATION_WORDS.search(seg)', 'or False'),
 ("🔴 classify: ADDRESS no longer wins over NAME",
  'if any(p.search(seg) for p in ADDRESS_TELLS) or LOCATION_WORDS.search(seg):\n        return "ADDRESS", seg',
  'if False:\n        return "ADDRESS", seg'),
 ("classify: a bare handle is offered as a name",
  'if seg.startswith("@") and " " not in seg:', 'if False:'),
 ("classify: a handle with a name after it is rejected too",
  'if seg.startswith("@") and " " not in seg:', 'if seg.startswith("@"):'),
 ("classify: an empty segment is offered as a name",
  'if not seg:\n        return "EMPTY", ""', 'if False:\n        return "EMPTY", ""'),
 ("classify: the length ceiling is dropped",
  'if not seg or len(seg) > 60:', 'if not seg:'),
 ("classify: the trailing clause is no longer trimmed",
  'seg = re.split(r"\\s+(?:I |we |you |and |it |that |this )", seg)[0].strip(" ,.")',
  'seg = seg.strip(" ,.")'),

 # --- proposals(): scope ----------------------------------------------
 ("🔴 proposals: entries with GOOD titles are rewritten too",
  'if not (_gate.looks_like_caption(title) or _gate.looks_like_description(title)):\n            continue',
  'if False:\n            continue'),
 ("proposals: nothing is ever collected",
  'out[kind].append({', 'out["NONE"].append({'),
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
