# Two pins still need per-building coordinates (Aranya, Beidaihe)

_opened 2026-09-22 · clear with `git rm status/owner/china-pin-coordinates.md`_

**Two of four resolved.** `Long Ma She` got a verified coordinate from an Amap
share link, and `Soft Square` is now a member of the `Long Ma She` place, so it
sits on that same verified point rather than needing one of its own.

| pin | status |
|---|---|
| `Long Ma She` | ✅ `22.6655240, 114.3647771` — Amap, converted GCJ-02 → WGS-84, confirmed by village name |
| `Soft Square` | ✅ member of the `Long Ma She` place, on the verified point |
| `Seashore Library` | ⏸ Aranya, Changli County |
| `Chapel of Music` | ⏸ Aranya, Changli County |

The two remaining are both Vector Architects buildings (2015 and 2023) in the
Aranya community, sharing one village-level coordinate at
`39.6561544, 119.3169543` — which reverse-geocodes to `阿那亚三期` (Aranya
Phase 3), so the **locality is right and only the precision is wrong**.

## 🔴 An Amap link works, but ONLY after conversion

`python3 scripts/gcj02.py <lat> <lng>` does it. The Long Ma She case is why it
is not optional:

| | distance from the old pin |
|---|---|
| Amap's raw number (GCJ-02) | **975 m** |
| after conversion to WGS-84 | **414 m** |

The datum offset was **589 m** — so pasting Amap's number straight in would have
put the pin *further* from the building than the wrong shared coordinate it
replaced, while looking precise.

**The locality check is what settles it, not the distance:** the converted point
reverse-geocodes to **长守 (Changshou)**, the village in Amap's own address field
(*Changshoucun No.40*). The raw number lands in **三河 (Sanhe)** — a different
village.

## What to send

An Amap share link is fine — that is what worked. So is Google or Apple Maps,
which need no conversion. **Say which app it came from**, because that is what
decides whether the number gets converted.
