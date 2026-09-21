# check-city-outliers.py: two coordinate errors no gazetteer could find

_2026-09-21 15:33 UTC · branch `scale-pinned-tours-automation-db`_

Added `scripts/check-city-outliers.py` — the first check here that needs **no
gazetteer**, and the 58 km error only it could find.

- **"Great Court, British Museum" sat 58 km from every other London entry**, in a
  business park in **GREAT NOTLEY, Essex**. A geocoder had matched the wrong word
  (*GREAT Court* → *GREAT Notley*) and answered confidently in the wrong county.
  🔴 **Neither gazetteer check could have found it** — the entry was `UNMATCHED`,
  and `check-same-name.py` needs a second entry of the same name. Moved to
  `51.519312, -0.126705` (OSM `type=museum`, Great Russell Street).
- Scores distance from the **median** of a city's **other** entries against that
  city's **own** spread. 🔴 **A question, never a verdict** — 76 of 4,174 flagged,
  most genuinely far-out sights (Cape Point is 48 km from Cape Town and correct).
- `--homonyms` reports one city NAME holding two places — **San Juan** (PH 1 /
  PR 7) and **Jericho** (US 1 / West Bank 1) — held out of the scoring rather
  than measured as one city.
- 21/21 selftests · **17/17 mutants, 2 proven equivalent** (the `min_others` rule
  is written twice, so neither copy can be broken alone).

Validator: **0 errors**, 530 warnings, `control clean`. Verdicts on file: 190.

**A second find, with a sharper tail.** *Modern Coffee House* (New York) sat
**22.9 km out, on Staten Island**. Geocoding the creator's own 📍 address returns
three results and the **third is our exact stored point** — Staten Island has an
East Broadway too, and the **postcode** separating them was in the part of the
caption **we cut off**. 🔴 **2,375 of 5,463 captions are exactly 140 characters
and 2,320 end mid-sentence** (`make-link-pin.py:621`), and creators put the
address LAST. Raised as an owner decision (`caption-truncation-140`) rather than
changed here — the caption is what a user reads.
