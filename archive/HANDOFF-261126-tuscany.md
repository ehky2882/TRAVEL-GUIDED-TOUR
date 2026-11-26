# HANDOFF 2026-11-26: Tuscany batch (Atlas Studio SIE 🇮🇹 launches, 3 singles; Atlas Studio FLR +2)

**What shipped:** 5 single-stop audio tours from a contributor drop. A new studio, **Atlas Studio SIE** (Siena and
the Tuscan hills), the 70th, with San Galgano Abbey, the Campatelli tower house in San Gimignano and the Teatrino di
Vetriano; and 2 Florence-area singles for FLR (Villa Gamberaia, Castello di Sammezzano). No walks.
- **Maker:** platform `dozent`, handle `atlas.sie`, uuid5 `atlas-maker:sie` = `241cc7ba-f823-5e63-8e79-1c59948ce760`.
- **Catalogue:** tours 2672 → 2677, makers 872 → 873, stops 3160 → 3165, cities 1180 → 1184 (Chiusdino, Reggello,
  San Gimignano, Pescaglia). Countries (106) and places (610) did not move.

**Source:** Dropbox drop, 5 folders. Triaged first; the contributor (arthur.yung) chose option (b) and asked for the
Gamberaia pin to be moved onto the villa (it was ~165 m north, at the gate). Full record: `drafts/tuscany-batch1/README.md`.
- Audio 111–123 s. Photos 27 delivered and shipped. Bilingual on 4 of 5 (Italian).
- gh-pages `5d0bf13`: 32 A only.

**Architect tags (Job 5):** 1 new name (Ferdinando Panciatichi Ximenes d'Aragona). **Places:** none.

**Checks:** `validate-tours-mirror` 0 errors, no warnings from the new tours · filenames align (32) ·
`spine-lookup` 5 asked, 0 failed · `join-places --max-move 100` nothing · `check-place-candidates` unchanged from main.
