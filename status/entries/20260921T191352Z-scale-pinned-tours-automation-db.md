# All 408 places now carry a description (79 written)

_2026-09-21 19:13 UTC · branch `scale-pinned-tours-automation-db`_

**Every place now has a description — 79 written, 408 of 408 complete.**

Owner asked for this after checking the place pages on build 178. Written in
four batches by how well grounded each one was, which is the whole point:

| source | n | |
|---|---|---|
| an Atlas tour member's own `longDescription` | 22 | distilled from owner-authored text |
| well-documented landmarks | 39 | Louvre, St Peter's, Pisa, Petronas, Strahov, Farnsworth… |
| small food businesses | 18 | 🔴 **grounded in the creators' own captions**, not invented |

🔴 **The 18 food entries are the ones worth knowing about.** I had no reliable
knowledge of most of them, and the honest material was already in hand: the pin
captions carry Kossar's street address (367 Grand), Chez Alain's (26 Rue
Charlot), Pecking House's Nashville×Taiwanese crossover and Peter Pan's
neighbourhood. Creator hype is **attributed or omitted**, never restated as
fact — "placed first in the 50 Top Pizza 2024 ranking" rather than "the best
pizza in the world".

⚠️ Applied through the byte-stability guard `merge-link-pins.py` uses: the
script **refuses to write** unless `Tours.json` already round-trips under
`indent=2, ensure_ascii=False` + trailing newline, so a 79-field edit cannot
silently reformat 240,000 lines. Each batch asserts `written + skipped ==
intended` and never overwrites an existing description.

Validator: 0 errors, 530 warnings, control clean. Lengths 103–1,280, median 261.
