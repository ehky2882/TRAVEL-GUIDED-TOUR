# HANDOFF 2026-11-27: Puglia batch (Atlas Studio BRI 🇮🇹 launches, 5 singles)

**What shipped:** 5 single-stop audio tours from a contributor drop under a new studio, **Atlas Studio BRI** (Bari),
the 76th: Teatro Margherita and Teatro Petruzzelli (Bari), Cattedrale di Troia, Abbazia di Santa Maria di Cerrate
(Lecce), Fontana Greca (Gallipoli). No walks. The first content in Puglia.
- **Maker:** platform `dozent`, handle `atlas.bri`, uuid5 `atlas-maker:bri` = `a3db3b82-d71b-5d58-ac11-0ce976e99588`.
  Contributor arthur.yung chose BRI for all five over PUG or a studio per town.
- **Catalogue:** tours 2719 → 2724, makers 878 → 879, stops 3207 → 3212, cities 1216 → 1220. Countries (106) and
  places (610) did not move.

**Source:** Dropbox drop, 5 folders, scripts 62–66. Triaged first, all 5 taken. Full record: `drafts/puglia-batch1/README.md`.
- Audio 113–125 s. Photos 25 delivered and shipped. Bilingual on 3 of 5 (Italian); both Bari theatres keep one name.
- gh-pages `907e5a6`: 30 A only. Petruzzelli photos arrived misnamed as Margherita; renamed by folder, checked by eye.

**Coordinates:** as supplied; no GROSS; Troia UNVERIFIABLE, checked by hand against the OSM footprint (in the street
in front, ~5 m outside the north edge).
**Architect tags (Job 5):** Francesco De Giglio, Angelo Cicciomessere.
**Place questions:** none (nothing within 5 km).
**Open:** none.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (30) · `spine-lookup`
5 asked, 0 failed · `join-places --max-move 100` and `check-place-candidates` list nothing for these five · live-URL hash: see the PR.
