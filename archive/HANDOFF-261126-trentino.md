# HANDOFF 2026-11-26: Trentino batch (Atlas Studio TNO 🇮🇹 launches, 6 singles)

**What shipped:** 6 single-stop audio tours from a contributor drop, under a new studio, **Atlas Studio TNO** (Trento,
with Rovereto and Avio), the 70th. No walks.
- **Maker:** platform `dozent`, handle `atlas.tno`, uuid5 `atlas-maker:tno` = `cda1160d-8001-5a71-9fb0-29888bc56bf0`.
  Code TNO because TRN is Turin and Trento has no IATA code; one studio for all three towns (contributor arthur.yung).
- **Catalogue:** tours 2672 → 2678, makers 872 → 873, stops 3160 → 3166, cities 1180 → 1183 (Trento, Rovereto,
  Avio). Countries (106) and places (610) did not move.

**Source:** Dropbox drop, 6 folders. Triaged first, all six taken. Full wiring record: `drafts/trentino-batch1/README.md`.
- Audio 101–126 s, 673 s. Photos 28 delivered and shipped. Bilingual on 4 of 6 (Italian).
- gh-pages `a74a46a`: 34 A only.

**Coordinates:** no GROSS; 2 UNVERIFIABLE checked by name against OSM (MUSE ~20 m, Simonino 29 m), Avio 204 m at the
gate as scripted. Nothing in the catalogue within 3 km: **no place questions.**

**Architect tags (Job 5):** 1 new name, Adamo d'Arogno, on its own line in each list.

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours · filenames align (34) · no geofence
overlaps · `spine-lookup` 6 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` nothing for
these tours · live-URL hash and `check-image-duplicates --maker TNO`: see the PR.
