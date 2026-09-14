# HANDOFF — 2026-09-13: the catalogue-wide coordinate sweep, and 13 repairs

## What happened

The coordinate check that found nine wrong coordinates on 2026-09-11 was run across the **whole**
catalogue: all 290 places, 1,480 single tours and 444 walk stops (2,214 coordinates, 2,349 Photon
lookups, every one HTTP 200). Link pins were not swept.

**Report (private artifact):** https://claude.ai/code/artifact/3a3e10d1-ced8-4837-a5cf-669619c9d48b

| | |
|---|---|
| Clearly misplaced, hand-typed (4 dp) | **13 locations, 20 stops** — repaired in this PR |
| Clearly misplaced, drop pipeline (14–15 dp) | **19 entries**, 268 m – 3.7 km, all north — **NOT repaired** |
| Probably off | **17 locations** — **NOT repaired**, owner to read |
| Verified automatically | 1,074 of 2,214; 641 no OSM match, 499 weak/junk/road-only |
| Recall | the method re-catches **9 of 9** of the 2026-09-11 defects at their old positions |

**Pipeline bias, measured catalogue-wide:** 14–15-dp coordinates sit north of their building-level
OSM match 208 of 262 times, median +20.4 m, p = 1.7e-22 (São Paulo 20/20, Kyoto 19/20, Barcelona
22/27 after its ten repairs). Hand-typed coordinates: 115/229, +0.1 m. The +20 m is not directly
comparable with `check-coordinates.py`'s +10 m (feature point vs reverse-geocode centre).

## The 13 repairs

Owner: *"fix the first 13."* Each was moved to **where its own script puts the listener**, from the
OSM outline, then reverse-geocoded to confirm what the new point sits on:

| Entry | Moved to | Moved |
|---|---|---|
| Egyptian Theatre (tour + Hollywood walk stop 4) | forecourt mouth, 6712 Hollywood Blvd | 1,054 m |
| Domino Park — Elevated Walkway | the raised footway (OSM way 1016721727) | 463 m |
| National Museum of Mexican Art (Pilsen walk stop 4) | 19th Street front | 386 m |
| La Rosaleda (tour + Retiro walk stop 4) | centre of the rose garden | 363 m |
| Bebelplatz (tour + Imperial Spine stop 2) | centre, at the book-burning memorial | 307 m |
| Square Saint-Louis (**place** + tour + Plateau walk stops 0 and 1) | centre of the park | 275 m |
| Chelsea Physic Garden | the Embankment wall | 240 m |
| Hackescher Markt (Scheunenviertel walk stop 0) | the square by the S-Bahn | 229 m |
| Park Avenue Armory | Park Avenue at 66th Street | 217 m |
| Magere Brug (tour / Canal Ring stop 5) | bridge centre / west bank | 195 / 203 m |
| The Old Operating Theatre | 9a St Thomas Street | 197 m |
| Cross Bones Graveyard | the Redcross Way gates | 152 m |
| Notre-Dame de Paris (tour + Paris Islands stop 4) | Point Zéro, on the parvis | 93 m |

- Single tours: centroid set to the new stop. Walks: centroid re-derived as the mean of stops;
  `walkingDistanceMeters` rescaled only where the straight-line route changed by >10% — Hollywood
  1600→1400, Imperial Spine 1500→1300, Pilsen 1800→2100, Scheunenviertel 800→1100.
- **Hackesche Höfe place dropped** (owner, 2026-09-13). The Scheunenviertel walk was a member only
  because its stop 0 (Hackescher Markt) sat on the Höfe; correcting it left one member, and a place
  needs two. `seed_from_toursjson.py` prunes it from Postgres on merge — no SQL owed.
- Radii unchanged: every new point is within its radius of the venue as the script describes it.
- Checks: `validate-tours.swift` 0 errors / 5 warnings (identical to `main`); `validate-tours-mirror.py`
  0 errors, selftest 32/32; seed generates 289 places; `check-place-candidates.py` EXACT/TIGHT/NEAR
  sections identical to `main`.

## Why they were wrong

Written up in `docs/lessons.md` § *"Centred on average" is not "correct"*. Short version: typed once
at city launches as a coordinate for the area, never looked up at the spot; the one check that
touched hand-typed cities measured **bias**, found none, and was read as clean; and walk stops and
places copied the wrong number, so one mistake became up to four entries.

## Still open

- The **19 pipeline defects** and **17 probable** ones in the report.
- The ~1,140 coordinates with no automatic verdict, weighted toward pipeline cities.
- The sweep scripts live only in the session scratchpad; if this is re-run, lift them into `scripts/`.
