# Six flagged pin coordinates checked — five were in the wrong place

_2026-09-13 18:22 UTC · branch `filtered-view-lesson`_

The owner asked what the six flagged pins were. Rather than list names, each was
checked against OpenStreetMap. **Five of six sat well away from their subjects**,
by **49 m to 759 m**. The sixth — Lok Hau Fook, Kowloon City — has no OSM entry
under its English or Chinese name and stays genuinely unverified.

🔴 **This entry originally said the five "can never fire", and that was wrong.**
The claim came from reading `triggerRadiusMeters: 30` and assuming a geofence.
**All 2,043 link-pin stops are `triggerMode: manual`**, and `ProximityMonitor`
registers regions only for `.geofenced` stops — so a link pin never auto-triggers
at all and that field is inert for them. Nobody's walk was silently broken. The
wording is corrected here rather than left for the next session to inherit.

**What was actually wrong:** the pin sat at the wrong place on the map, so anyone
browsing — or expanding the map on that creator — saw it at the wrong building,
and coordinate-based place grouping would have grouped it wrongly too.

**Fixed in [#870](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/870)**, with
Nominatim and Photon agreeing to Δ0 m on each before anything was written.

**The tell needed no lookup:** four of the six carried 3-decimal coordinates,
~110 m of resolution. Worth checking mechanically on every future pin batch — it
needs no network and no geocoder.
