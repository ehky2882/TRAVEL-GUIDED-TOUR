#!/usr/bin/env python3
"""Break one guard in `check-pin-title.py`; the selftest MUST go red.

🔴 A gate that cannot fail is worse than no gate: it reports clean and people
stop looking. Both directions matter here — a rule that stops catching captions
lets the next Torre Velasca through, and a rule that starts catching real names
gets switched off within a week.
"""
import os
import subprocess
import sys

SRC = "scripts/check-pin-title.py"
TMP = "scripts/_mutant_pin_title.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("🔴 caption: an @handle title passes",
  'if "@" in text:', 'if False:'),
 ("🔴 caption: an emoji title passes",
  'if any(unicodedata.category(c) == "So" for c in text):', 'if False:'),
 ("caption: a question mark passes",
  'if any(c in text for c in "?!"):', 'if False:'),
 ("caption: an ellipsis passes",
  'if text.endswith(("…", "...")):', 'if False:'),
 ("caption: an empty title passes", 'if not text:\n        return "empty title"',
  'if False:\n        return "empty title"'),
 ("🔴 caption: the word limit is so tight it eats real names",
  'MAX_TITLE_WORDS = 9', 'MAX_TITLE_WORDS = 2'),
 ("caption: the word limit is dropped",
  'if len(longest) > MAX_TITLE_WORDS:', 'if False:'),
 # 🔴 The bilingual split. Counting the whole "English | native script" string
 # counts the name twice, so EVERY Tokyo/Seoul/Bangkok/Saigon title reads as a
 # caption -- and this gate REFUSES in merge-link-pins.py, so that mistake
 # blocks a whole city batch. It shipped that way and flagged hundreds of live
 # titles before anyone ran the gate over the existing catalogue.
 ("🔴 caption: the bilingual halves are counted together again",
  'longest = max((part.split() for part in text.split("|")),\n                  key=len, default=[])',
  'longest = text.split()'),
 ("caption: only the FIRST half is counted, so a long native name escapes",
  'longest = max((part.split() for part in text.split("|")),\n                  key=len, default=[])',
  'longest = text.split("|")[0].split()'),
 ("🔴 description: 'The' is treated as an indefinite article, killing real names",
  'if first in ("a", "an"):', 'if first in ("a", "an", "the"):'),
 ("description: the rule is dropped", 'if first in ("a", "an"):', 'if False:'),
 ("🔴 duplicate: an entry matches ITSELF, so every pin is flagged",
  'if other.get("id") == entry.get("id"):\n            continue',
  'if False:\n            continue'),
 ("🔴 duplicate: the radius is ignored, so two real places sharing a name pair",
  'if gap <= radius_m:', 'if True:'),
 ("duplicate: titles need not match",
  'if fold(other.get("title")) != title:\n            continue',
  'if False:\n            continue'),
 ("duplicate: an entry with no coordinate is flagged",
  'if lat is None:\n        return ""', 'if False:\n        return ""'),
 ("duplicate: an entry with no title is flagged",
  'if not title:\n        return ""', 'if False:\n        return ""'),
 ("🔴 duplicate: the message asserts a verdict instead of asking",
  '"if they are different subjects, one title is wrong"', '"this is wrong"'),
 ("findings: only the first reason is returned",
  'out.append(reason)\n    if catalog is not None:', 'return out\n    if catalog is not None:'),
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
