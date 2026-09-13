# 6 new link-pin coordinates — FIVE ARE OUTSIDE THEIR OWN GEOFENCE

_opened 2026-09-13 · clear with `git rm status/owner/insightcities-pin-coords.md`_

From [#867](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/867) (52 @insightcities pins).
Minted from best-knowledge estimates because Instagram's oEmbed carries no location.

🔴 **Checked against OpenStreetMap 2026-09-13. Every link pin has a
`triggerRadiusMeters` of 30 — so anything more than 30 m out never fires at all.**

| pin | ours | OSM says | off by | fires? |
|---|---|---|---|---|
| Corso Karlín (Prague) | 50.0958, 14.46 | 50.09161, 14.45159 | **759 m** | ❌ |
| Brummel House (Plzeň) | 49.746, 13.3745 | 49.74609, 13.36422 | **738 m** | ❌ |
| Masaryčka (Prague) | 50.0895, 14.437 | 50.08835, 14.43418 | **238 m** | ❌ |
| YMCA Palace (Prague) | 50.0879, 14.431 | 50.08898, 14.43127 | **121 m** | ❌ |
| Fragment / Lilith (Prague) | 50.0965, 14.461 | 50.09660, 14.46033 | **49 m** | ❌ |
| Lok Hau Fook (Kowloon City) | 22.3305, 114.1912 | *no OSM match* | unknown | ⚠️ |

⚠️ **Lok Hau Fook could not be verified this way** — OSM has no entry under the
English or Chinese name. Unverified is not "fine": it is the one still unchecked.

**Why this matters more than it looks:** a wrong coordinate is the defect that
passes every other check. The validator passes, CI compiles, every URL returns
200 — and the pin simply never triggers. Nobody reports it, because nothing
visibly breaks.

**The tell was in the numbers all along:** four of the six carry 3-decimal
coordinates (`14.46`, `14.461`, `14.437`, `14.431`), which is ~110 m of
resolution against a 30 m geofence. A 3-dp coordinate cannot land inside this
radius except by luck.

**The fix is a plain coordinate edit** in `Tours.json` against each pin's existing
`id` — no filename or image concerns, these are link pins. **Not applied yet:** a
wrong correction is as invisible as a wrong original, so the OSM figures are
offered for the owner to sanity-check first.
