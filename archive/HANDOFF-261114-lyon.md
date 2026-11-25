# HANDOFF 2026-11-14: Lyon launches (Atlas Studio LYS 🇫🇷, 34 singles)

**What shipped:** a new studio, **Atlas Studio LYS**, the 66th, with 34 single-stop audio tours of Lyon and no walks.
- **Maker:** platform `dozent`, handle `atlas.lys`, uuid5 `atlas-maker:lys` = `666b2520-de5e-5261-9834-031e34ca8adb`.
- **Catalogue:** tours 2562 → 2596, makers 818 → 819, stops 3050 → 3084, cities 1109 → 1112 (Villeurbanne, Éveux,
  Colombier-Saugnieu). Countries (104) and places (610) did not move.

**Source:** a Dropbox drop from the contributor (arthur.yung), 34 folders. Triaged first; the contributor approved it as
proposed ("go, all as proposed"). Full wiring record: `drafts/lyon-batch1/README.md`.
- Audio 99–132 s, 3,946 s. Photos 144 delivered, 143 shipped (one byte duplicate). Bilingual on 13 of 34 (French).
- gh-pages `f0c486d`: 177 A only.

**Coordinates:** 0 GROSS; 1 moved (La Tourette, ~125 m onto the building). Bias 8/16, +1.7 m, p = 1 — no northward
offset in this drop.

**Architect tags (Job 5):** 12 new names on one line in each list. **Places:** one question for Edward,
`status/owner/place-lyon.md` (Cour des Voraces, 12 m).

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours (745 overall, down from 747 after two tag
fixes) · filenames align (177) · no geofence overlaps · `spine-lookup` 34 asked, 0 failed · `join-places --max-move 100`
nothing · `check-place-candidates` only Cour des Voraces. Live-URL hash check and `check-image-duplicates --maker LYS`:
see the PR.
