#!/usr/bin/env python3
"""Break one guard in `fold-city-names.py`; the selftest MUST go red.

🔴 This tool REWRITES a grouping key across the catalogue. A guard that cannot
fail here merges two real cities into one and nothing downstream would notice:
`validate-tours` has no opinion on city names, and the count in Settings would
simply be smaller.
"""
import os
import subprocess
import sys

SRC = "scripts/fold-city-names.py"
TMP = "scripts/_mutant_fold_city.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("🔴 bare_form: a PREFIX folds too, so Miami Beach dies",
  'for pattern in (PAREN, COMMA):',
  'for pattern in (PAREN, COMMA, re.compile(r"^(\\w+)\\s+\\w+$")):'),
 ("bare_form: the paren pattern is dropped",
  'for pattern in (PAREN, COMMA):', 'for pattern in (COMMA,):'),
 ("bare_form: the comma pattern is dropped",
  'for pattern in (PAREN, COMMA):', 'for pattern in (PAREN,):'),
 ("🔴 bare_form: a name that is only brackets folds to empty",
  'if stem and stem != text:', 'if stem != text:'),
 ("🔴 foldable: the bare form need not exist",
  'if stem is None or stem not in seen:\n            continue',
  'if stem is None:\n            continue\n        seen.setdefault(stem, seen[city])'),
 ("🔴 foldable: proximity is not required (Springfield, Missouri)",
  'if board.metres(la, lo, lb, lob) > near_km * 1000:\n            continue',
  'if False:\n            continue'),
 ("🔴 foldable: the country need not match (London, Ontario)",
  'if ca != cb:\n            continue', 'if False:\n            continue'),
 ("apply_fold: nothing is actually rewritten",
  'entry["city"] = rename[city]', 'pass'),
 ("apply_fold: every city is rewritten, not just the variants",
  'if city in rename:', 'if True:'),
 ("apply_fold: the changed count is inflated",
  'changed += 1', 'changed += 2'),
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
