# check-coordinates.py --pins: the 2,318 pins audited for the first time

_2026-09-15 19:14 UTC · branch `check-coordinates-pins`_

🟢 **`check-coordinates.py --pins` exists.** The 2,318 link pins have now been audited as a set for
the first time — **offline, no geocoder, about a second.**

The Nominatim path could never do this: `from_catalog` reads `d["tours"]` and matches
`Atlas Studio {CODE}`, so **no pin could ever match it**, and 2,318 pins at `SLEEP=1.1` with ≥2
calls each is 2–3 hours anyway. So `--pins` asks a different question — *is this point inconsistent
with its own neighbours and its own stated city* — which needs no network.

| finding | pins | reading |
|---|---:|---|
| **CITY-OUTLIER** | **0** | 🟢 no pin is in the wrong city. #913/#917/#920's Tokyo precision work closed this class |
| **SHARED-POINT** | **11** on 3 points | the real residue — Strahov Library (×5), Marin County Civic Center (×3), Gotokuji Temple (×3) |
| **LOW-PRECISION** | **36** | ≤3 dp ≈ 110 m — a neighbourhood, not a door. Listed by city in the output |
| *shared-but-placed* | *199* | **expected, not a defect** — see below |

**42 pins carry a real flag (1.8%).**

🔴 **The place-awareness is the whole point, and I built it wrong first.** The naive version flagged
**210 pins on 60 points** as SHARED-POINT. Almost all of them are *correctly* collapsed into a place
page — which is the mechanism that stops them stacking on the map. Teaching the check about
`place.tourIds` took it from 210 to **11**. A check that cries wolf on 199 correct pins would have
been read once and ignored.

⚠️ That is the same error, in the same afternoon, as the retracted "~32 invisible pins" finding:
**counting raw coordinate groups without checking the mechanism built to solve them.** The module
docstring now records that membership is `place.tourIds`, never a `placeId` on the pin.

⚠️ **Also caught in review: my first patch clobbered the EXISTING `report()`.** A `total = len(rows)`
replacement matched in the drop/maker path instead of `report_pins()`. Repaired, and verified by
`git diff --stat` reading **193 insertions, 0 deletions** — a pure addition. A string replace that
does not say WHICH function it targets is a loaded gun in a 568-line file.

⚠️ Flags are readings, not verdicts. SHARED-POINT is occasionally correct (two venues in one
building); this project has already moved three pins on a district-centroid distance and got 11 m
right, 220 m wrong and 100 m wrong.
