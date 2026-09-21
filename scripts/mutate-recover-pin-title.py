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
  'while seg != prev:\n        prev = seg\n        seg = strip_decoration(strip_trailing_handles(seg))\n    if not seg:',
  'while seg != prev:\n        prev = seg\n        seg = strip_decoration(strip_trailing_handles(seg))\n    if False:'),
 ("classify: the length ceiling is dropped",
  'if not seg or len(seg) > 60:', 'if not seg:'),
 ("classify: the trailing clause is no longer trimmed",
  'seg = re.split(r"\\s+(?:I |we |you |and |it |that |this )", seg)[0].strip(" ,.")',
  'seg = seg.strip(" ,.")'),

 # --- name_from_caption(): 🔴 the handle must only CORROBORATE ---------
 ("🔴 handle: a name is returned without the caption confirming it",
  'if acc == want:', 'if True:'),
 ("🔴 handle: a PARTIAL overlap is accepted as a full match",
  'if acc == want:', 'if want.startswith(acc):'),
 ("handle: the short-handle floor is dropped",
  'if len(want) < 4:\n        return ""', 'if False:\n        return ""'),
 ("handle: trailing punctuation is left on the name",
  'return phrase.strip(" .,:;!?-–—")', 'return phrase'),
 ("🔴 handle: the marker is NOT stripped, so every handle corroborates ITSELF",
  'body = re.sub(r"📍[^\\n#]{0,80}", " ", caption)', 'body = caption'),
 ("🔴 handle: a HANDLE is promoted to NAME even with no caption spelling",
  'spelled = name_from_caption(value, body)\n            if spelled:',
  'spelled = name_from_caption(value, body) or value\n            if spelled:'),

 # --- the three guards that blocked 15 owner-reviewed proposals -------
 ("🔴 classify: a trailing @handle is left on the name",
  'seg = strip_decoration(strip_trailing_handles(seg))',
  'seg = strip_decoration(seg)'),
 ("🔴 classify: handles are stripped BEFORE the bare-handle check, so a bare "
  "handle becomes empty and is never seen",
  'if seg.startswith("@") and " " not in seg:\n        return "HANDLE", seg\n    # 🔴 Only AFTER',
  '# moved\n    if False:\n        return "HANDLE", seg\n    # 🔴 Only AFTER'),
 ("strip_trailing_handles: a handle ANYWHERE is removed, not just trailing",
  'r"(\\s*@[\\w.]+)+\\s*$"', 'r"(\\s*@[\\w.]+)+"'),
 ("🔴 classify: the European street-then-number tell is dropped",
  'r"allee|laan|straat|gata|vej|gade|via|rue|calle)\\s+\\d{1,4}\\b", re.I),', ''),
 ("🔴 classify: the four-digit-postcode tell is dropped",
  're.compile(r",\\s*\\d{4}\\s+[A-Z]"),', ''),
 ("🔴 is_place_name: a bare CITY is offered as a venue",
  'if kind == "NAME" and is_place_name(value, places):\n            kind = "ADDRESS"',
  'if False:\n            kind = "ADDRESS"'),
 ("is_place_name: any name CONTAINING a city word counts as a place",
  'if key in place_names:\n        return True',
  'if any(k in key for k in place_names):\n        return True'),
 ("is_place_name: ONE part being a place is enough",
  'return bool(parts) and all(p in place_names for p in parts)',
  'return bool(parts) and any(p in place_names for p in parts)'),
 ("place_vocabulary: countries are not collected",
  'for field in ("city", "country"):', 'for field in ("city",):'),

 # --- place_key / strip_decoration ------------------------------------
 ("🔴 place_key: accents are DELETED rather than decomposed, so Cordoba "
  "never matches Cordoba",
  't = unicodedata.normalize("NFKD", text or "")\n    t = "".join(c for c in t if not unicodedata.combining(c))',
  't = text or ""'),
 ("place_key: punctuation is not folded away",
  'return " ".join(re.sub(r"[^a-z0-9 ]", " ", t.lower()).split())',
  'return t.lower().strip()'),
 ("🔴 strip_decoration: emoji are left inside the name",
  'if unicodedata.category(c) not in ("So", "Sk", "Cs", "Cf"))',
  'if True)'),
 ("strip_decoration: a name with no letters left is still offered",
  'return out if any(c.isalnum() for c in out) else ""', 'return out'),

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
