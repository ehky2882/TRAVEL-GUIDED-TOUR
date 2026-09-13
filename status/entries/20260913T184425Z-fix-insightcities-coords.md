# Five pin coordinates corrected — and a claim of mine corrected with them

_2026-09-13 18:44 UTC · branch `fix-insightcities-coords`_

**Five of the six @insightcities pins are fixed**, verified by two geocoders
agreeing to Δ0 m before anything was written:

| pin | was | now | moved |
|---|---|---|---|
| Corso Karlín | 50.0958, 14.46 | 50.09161, 14.45159 | 759 m |
| Brummel House | 49.746, 13.3745 | 49.74609, 13.36422 | 738 m |
| Masaryčka | 50.0895, 14.437 | 50.08835, 14.43418 | 238 m |
| YMCA Palace | 50.0879, 14.431 | 50.08898, 14.43127 | 121 m |
| Fragment (Lilith) | 50.0965, 14.461 | 50.0966, 14.46033 | 49 m |

Both `stops[0]` and the `centroid*` pair moved together. Validator: **0 errors**,
3 pre-existing warnings unrelated to these pins. Exactly 5 pins differ; counts
unchanged.

🔴 **CORRECTION — I said these "can never fire". That was wrong.** I read
`triggerRadiusMeters: 30` on the pins and assumed a geofence. **All 2,043
link-pin stops are `triggerMode: manual`**, and `ProximityMonitor` registers
regions only for `.geofenced` stops — so **a link pin never auto-triggers at all
and that radius field is inert for them.** Nobody's walk was silently broken.

**What was actually wrong:** the pin sat at the wrong place on the map — 759 m
away in Corso Karlín's case — so anyone browsing, or expanding the map on that
creator, saw it at the wrong building, and place-grouping (which works off
coordinates) would have grouped it wrongly too. Real, worth fixing, not urgent.

**The habit, again:** I took a field's presence as evidence of its effect without
checking what consumes it. Same shape as the three earlier today.

⚠️ **Lok Hau Fook remains unverified** and is now its own owner item — OSM has no
entry under either name.
