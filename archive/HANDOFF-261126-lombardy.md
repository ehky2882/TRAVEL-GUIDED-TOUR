# HANDOFF 2026-11-26: Lombardy batch (Atlas Studio LOM 🇮🇹 launches, 16 singles; Atlas Studio MIL +3)

**What shipped:** 19 single-stop audio tours from a contributor drop. A new studio, **Atlas Studio LOM** (Lombardia),
the 74th, with 16 singles across the lakes, Varese, Bergamo, the Adda, Monza, Valtellina, Mantua and Lonato; and 3
Milan-area singles for MIL (Villa Necchi Campiglio, San Siro and Leonardo's Horse, Palazzo Mondadori in Segrate). No walks.
- **Maker:** platform `dozent`, handle `atlas.lom`, uuid5 `atlas-maker:lom` = `0050f2e3-ec73-5205-9eaa-7ab9c795f79a`.
  Contributor arthur.yung chose MIL + one regional LOM over a studio per city.
- **Catalogue:** tours 2694 → 2713, makers 876 → 877, stops 3182 → 3201, cities 1197 → 1212. Countries (106) and
  places (610) did not move.

**Source:** Dropbox drop, 19 folders. Triaged first, all 19 taken. Full record: `drafts/lombardy-batch1/README.md`.
- Audio 104–128 s. Photos 95 delivered and shipped. Bilingual on 10 of 19 (Italian).
- gh-pages `6e2ca5e`: 114 A only.

**Coordinates:** no GROSS. Three moved onto their subject on the contributor's OK (Mondadori 272 m, Rocca di Lonato
160 m, Buco del Piombo 104 m). No geofence overlaps.

**Architect tags (Job 5):** 7 new names (Portaluppi, Buzzi, BBPR, Vietti-Violi, Porcinai, Canonica, Röthlisberger).
**Place question for Edward:** Villa Necchi Campiglio tour vs the @__dreamspaces pin, 36 m (`status/owner/place-villa-necchi-campiglio`).

**Checks:** `validate-tours-mirror` 0 errors (one warning: Buco del Piombo has no place-type tag, a cave fits none) ·
filenames align (114) · `spine-lookup` 19 asked, 0 failed · `join-places --max-move 100` nothing new ·
`check-place-candidates` adds only the Necchi pair · live-URL hash: see the PR.
