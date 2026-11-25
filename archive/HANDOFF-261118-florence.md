# HANDOFF 2026-11-18: Florence launches (Atlas Studio FLR 🇮🇹, 34 singles)

**What shipped:** a new studio, **Atlas Studio FLR**, the 67th, with 34 single-stop audio tours of Florence and no walks.
- **Maker:** platform `dozent`, handle `atlas.flr`, uuid5 `atlas-maker:flr` = `2ef7f356-9ba8-552f-a182-7ffbd7d78c7b`.
- **Catalogue:** tours 2596 → 2630, makers 840 → 841, stops 3084 → 3118, cities 1120 → 1121 (Campi Bisenzio).
  Countries (104) and places (610) did not move.

**Source:** a Dropbox drop from the contributor (arthur.yung), 34 folders. Triaged first; approved "add all 34, move
laurenziana, skip piano". Full wiring record: `drafts/florence-batch1/README.md`.
- Audio 93–136 s, 3,831 s. Photos 164 delivered and shipped. Bilingual on 13 of 34 (Italian).
- gh-pages `12351be`: 198 A only.

**Coordinates:** 0 GROSS; 1 moved (Laurenziana, 84 m onto the library). Bias 11/20, +1.8 m, p = 0.82: no northward
offset.

**Architect tags (Job 5):** 13 new names on one line in each list. **Places:** three questions for Edward,
`status/owner/place-florence.md` (Laurentian Library, Ponte Vecchio, Trattoria Sostanza).

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours · filenames align (198) · no geofence
overlaps · `spine-lookup` 34 asked, 0 failed · `join-places --max-move 100` nothing new · `check-place-candidates` only
the three above. Live-URL hash check and `check-image-duplicates --maker FLR`: see the PR.
