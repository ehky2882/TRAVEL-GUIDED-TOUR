# HANDOFF 2026-11-26: Piedmont batch (Atlas Studio PIE 🇮🇹 launches, 5 singles)

**What shipped:** 5 single-stop audio tours from a contributor drop, under a new studio, **Atlas Studio PIE**
(Piemonte), the 72nd: Manta Castle, Masino Castle and Park (Caravino), the Enrico Collection at Villa Flecchia
(Magnano), Villa Taranto Botanical Gardens (Verbania), St Michael's Abbey | Sacra di San Michele (Sant'Ambrogio di
Torino). No walks.
- **Maker:** platform `dozent`, handle `atlas.pie`, uuid5 `atlas-maker:pie` = `fbe4066b-2aa0-51ba-b03d-cd8cefe988be`.
  One regional studio because none of the five is in Turin (27–117 km out); contributor arthur.yung chose PIE over TRN.
- **Catalogue:** tours 2683 → 2688, makers 874 → 875, stops 3171 → 3176, cities 1187 → 1192. Countries (106) and
  places (610) did not move.

**Source:** Dropbox drop, 5 folders. Triaged first, all five taken. Full wiring record: `drafts/piedmont-batch1/README.md`.
- Audio 116–142 s, 615 s. Photos 29 delivered and shipped. Bilingual on all 5 (Italian).
- gh-pages `c8c9ca7`: 34 A only.

**Coordinates:** no GROSS; 3 UNVERIFIABLE checked by name against OSM (Masino ~43 m, Flecchia ~25 m, Taranto at the
gate). Nothing in the catalogue within 5 km: **no place questions.** No architect tags (none credited).

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours · filenames align (34) · no geofence
overlaps · `spine-lookup` 5 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` unchanged by
this batch · live-URL hash and `check-image-duplicates --maker PIE`: see the PR.
