# Five of six flagged pin coordinates are outside their 30 m geofence

_2026-09-13 18:22 UTC · branch `filtered-view-lesson`_

The owner asked what the six flagged pins were. Rather than list names, each was
checked against OpenStreetMap.

**Five of six are far enough out that they can never fire.** Every link pin
carries `triggerRadiusMeters: 30`, and the misses run **49 m to 759 m**. The
sixth — Lok Hau Fook, Kowloon City — has no OSM entry under its English or
Chinese name and remains genuinely unverified.

**The tell was visible without any lookup:** four of the six carry 3-decimal
coordinates, ~110 m of resolution against a 30 m radius. **A 3-dp coordinate
cannot reliably land inside a 30 m geofence** — that is worth checking
mechanically on every future pin batch, since it needs no network and no
geocoder.

Corrections are **not applied**: a wrong correction is exactly as invisible as a
wrong original, so the figures went to the owner first.
