# Three pins still need per-building coordinates (Changshou Village + Aranya)

_opened 2026-09-22 · clear with `git rm status/owner/china-pin-coordinates.md`_
**One of four done.** `Long Ma She` now has a verified coordinate from an Amap
share link the owner sent. **Three still need one.**

| pin | status |
|---|---|
| `Long Ma She` | ✅ `22.6655240, 114.3647771` — from Amap, converted GCJ-02 → WGS-84 |
| `Soft Square` | ⏸ Changshou Village, still on the old village-level point |
| `Seashore Library` | ⏸ Aranya, Changli County |
| `Chapel of Music` | ⏸ Aranya, Changli County |

## 🔴 An Amap link is usable, but ONLY after conversion

`scripts/gcj02.py` does it (`python3 scripts/gcj02.py <lat> <lng>`), and the
Long Ma She case shows why it is not optional:

| | distance from the old pin |
|---|---|
| Amap's raw number (GCJ-02) | **975 m** |
| after conversion to WGS-84 | **414 m** |

The datum offset here is **589 m**. Pasting Amap's number straight in would have
put the pin *further* from the building than the wrong shared coordinate it
replaced — while looking like a careful fix.

**And the locality check settles which one is right, independently:** the
converted point reverse-geocodes to **长守 (Changshou)**, the village named in
Amap's own address field (*Changshoucun No.40*). The raw number lands in
**三河 (Sanhe)** — a different village.

## What to send for the remaining three

An Amap share link is fine — that is what worked here. So is Google or Apple
Maps, which need no conversion. Either way, say which app it came from, because
that is what decides whether the number gets converted.
