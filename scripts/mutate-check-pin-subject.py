#!/usr/bin/env python3
"""Break one guard in `check-pin-subject.py` at a time; the selftest MUST go red.

🔴 A green selftest proves nothing on its own. Across #988/#993/#995 **nine
guards in this repo were initially unable to fail**, and one of them was masked
by a second guard checking the same thing — every one read as an ordinary green
check. Mutation testing is the only thing that found them.

Run from the repo root:  python3 scripts/mutate-check-pin-subject.py

A mutant whose anchor no longer matches is reported as SKIP and fails the run —
a mutation that cannot be applied is not a mutation that was caught.
"""
import shutil, subprocess, sys, os

SRC = "scripts/check-pin-subject.py"
TMP = "scripts/_mutant_check_pin_subject.py"
ORIG = open(SRC, encoding="utf-8").read()

MUTANTS = [
 ("yes_no: an unparseable reply becomes NO",
  '        return False\n    return None', '        return False\n    return False'),
 ("verdict: gate A no is treated as a pass",
  'if not gate_a:\n        return "UNUSABLE"', 'if not gate_a:\n        return "CONFIRMS"'),
 ("verdict: CONTRADICTS never fires",
  'return "CONFIRMS" if gate_b else "CONTRADICTS"', 'return "CONFIRMS"'),
 ("verdict: an unanswered gate is a verdict anyway",
  'if gate_a is None or (gate_a and gate_b is None):\n        return "UNCHECKED"',
  'if False:\n        return "UNCHECKED"'),
 ("uncorroborated: the venue-handle filter is dropped",
  'if _cpc.venue_handles(pin):\n            continue', 'if False:\n            continue'),
 ("uncorroborated: the caption-overlap filter is dropped",
  'if title_words & caption_words:\n            continue', 'if False:\n            continue'),
 ("uncorroborated: both filters are bypassed together",
  '    out = []\n    for pin in catalog.get("linkPins") or []:',
  '    return list(catalog.get("linkPins") or [])\n    out = []\n    for pin in catalog.get("linkPins") or []:'),
 ("gate A: the compound question — it names the title",
  '"Does this image show ONE specific', '"Is this %r? Does this image show ONE specific" % "X" + "'),
 ("gate A: the rejection list is dropped",
  '"Answer NO if it is instead: a person or people with no identifiable "',
  '"" or "'),
 ("gate B: the distractors are never named",
  'lines.append(f"In particular, answer NO if it is instead: {named}.")', 'pass'),
 ("gate B: distractors are named even when there are none",
  'if distractors:\n        named', 'if True:\n        named'),
 ("gate C: no UNKNOWN escape hatch",
  '"cannot identify it, reply exactly: UNKNOWN.")', '"cannot identify it, guess.")'),
 ("digest: the image URL stops mattering",
  'pin.get("heroImageURL") or ""', '""'),
 ("digest: the title stops mattering",
  'payload = json.dumps([pin.get("title") or "", pin.get("heroImageURL") or "",',
  'payload = json.dumps(["", pin.get("heroImageURL") or "",'),
 ("--maker: matches anywhere in the record, not the creator field",
  'if author == want or makers.get(pin.get("makerId")) == want:',
  'if want in json.dumps(pin).lower():'),
 ("--maker: the maker-handle route is dropped",
  'if author == want or makers.get(pin.get("makerId")) == want:',
  'if author == want:'),
 ("--maker: the @ is not stripped",
  'want = needle.strip().lstrip("@").lower()', 'want = needle.strip().lower()'),
 ("--maker: an empty needle selects nothing",
  'if not want:\n        return pins', 'if not want:\n        return []'),
 ("neighbours: the city filter is dropped",
  'if (other.get("city") or "").strip().lower() != city:\n            continue',
  'if False:\n            continue'),
 ("neighbours: the entry does not skip itself",
  'if other["id"] == pin["id"]:\n            continue', 'if False:\n            continue'),
]

caught = missed = 0
for name, find, repl in MUTANTS:
    if ORIG.count(find) != 1:
        print(f"  SKIP (anchor {ORIG.count(find)}x) {name}"); missed += 1; continue
    open(TMP, "w", encoding="utf-8").write(ORIG.replace(find, repl))
    r = subprocess.run([sys.executable, TMP, "--selftest"],
                       capture_output=True, text=True)
    os.remove(TMP)
    ok = r.returncode != 0
    print(f"  {'caught' if ok else '🔴 MISSED'}  {name}")
    caught += ok; missed += not ok

print(f"\nMUTATIONS {caught}/{caught+missed} caught")
sys.exit(1 if missed else 0)
