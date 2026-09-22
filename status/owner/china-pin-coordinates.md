# ONE pin still needs a coordinate — Chapel of Music, Aranya

_opened 2026-09-22 · clear with `git rm status/owner/china-pin-coordinates.md`_

**Three of four resolved, and the fourth is now a single pin.**

| pin | status |
|---|---|
| `Long Ma She` | ✅ `22.6655240, 114.3647771` — Amap, converted, confirmed by village name |
| `Soft Square` | ✅ member of the `Long Ma She` place, on that verified point |
| `Seashore Library` | ✅ **already correct** — see below |
| `Chapel of Music` | ⏸ **the only one left** |

## 🔴 The Beidaihe pair was NOT what it looked like

Both pins sat on `39.6561544, 119.3169543`, which read as a shared village-level
guess. The owner's Amap link for the library
(*Joint Publishing Seaside Commonweal Library (Lonely Library)*, Binhai New
Avenue) converts to `39.6561895, 119.3169566` — **4 m from that point.**

So the shared coordinate **is the Seashore Library's correct position**, and the
defect is narrower and different: **`Chapel of Music` was given the library's
coordinate.** Only the chapel needs a new one.

⚠️ **Both pins are deliberately left exactly coincident.** Applying the 4 m
refinement to the library alone would drop the pair out of the `EXACT · ASK`
tier — where it is visible and addressed to the owner — into the 81-row `TIGHT`
list, where it would be effectively invisible. **A 4 m improvement is not worth
hiding the real fault**, so the refinement waits until the chapel's coordinate
arrives and both can be set together.

## 🔴 Why the conversion is not optional — the sharpest case yet

| | distance from the pin |
|---|---|
| Amap's raw number for the library (GCJ-02) | **551 m** |
| after conversion to WGS-84 | **4 m** |

Pasting Amap's raw number in would have taken a pin that was **already correct**
and moved it **551 m**. That is rule 8d's own warning — *an address-only geocode
would have moved a CORRECT pin* — arriving through a different door.

`python3 scripts/gcj02.py <lat> <lng>` does the conversion.

## What to send

An Amap share link for **Chapel of Music** (阿那亚音乐厅 / the Aranya music hall,
Vector Architects, 2023). Google or Apple Maps works too and needs no
conversion — **say which app it came from**, because that decides whether the
number gets converted.
