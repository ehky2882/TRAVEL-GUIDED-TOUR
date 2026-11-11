# HANDOFF 2026-11-04: Athens launches (Atlas Studio ATH 🇬🇷, 29 singles)

**What shipped:** a new studio, **Atlas Studio ATH**, the 59th, with 29 single-stop audio tours of Athens and no walks.
- **Maker:** platform `dozent`, handle `atlas.ath`, uuid5 `atlas-maker:ath` = `a274e39f-e266-5eae-b21a-8d9fad136299`.
- **Catalogue:** tours 2326 → 2355, makers 730 → 731, stops 2785 → 2814, cities 1080 → 1081 (Kallithea, for SNFCC).
  Countries (104) and places (507) did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 29 folders numbered 01–30 (26 absent).
Triage went to the contributor first; they approved it as proposed, asked for all four Hilton architects to be tagged,
asked for the funicular to sit at its ascending station, and asked for Atlantikos, The Clumsies and Diporto to be
stacked on the existing pins (left to Edward — see below).
- **Audio:** 77–138 s each. Not transcribed against the scripts.
- **Photos:** 127 delivered and shipped, all 1200×900 WebP, no byte duplicates.
- **Bilingual `English | Ελληνικά`** on 16. See `drafts/athens-batch1/README.md`.

**Coordinates:** one moved (Lycabettus Funicular, ~20 m to the OSM lower station). `check-coordinates.py --drop`
returned COULD NOT VERIFY on two runs (Nominatim dropping ~25% of calls); what it reached was 4–81 m off, SNFCC 149 m.
Six more were confirmed by hand lookups. Not certified — a later session with a steadier geocoder could re-run it.

**Architect tags (Job 5):** 11 new names on one line in each list (README lists them and what was not tagged).

**Places:** none created. Three same-venue pairs the contributor asked to stack, plus the Lycabettus part-vs-whole
question, are on Edward's board (`status/owner/athens-launch.md`).

**gh-pages:** `1d48798e`, one commit adding 156 files (29 audio, 127 images), built with plumbing. Diff was 156 A only.

**Checks:** `validate-tours-mirror` 0 errors, 718 warnings (unchanged from before the batch) · filenames align (156) ·
no overlapping geofences among the 29 · `spine-lookup` 29 asked, 0 failed · `join-places --max-move 100` nothing.

**Content notes (audio already recorded):** Nolan's menu and the Conrad's April 2026 rename will date; the 2025 death
year for Stavros Melissinos was not verified.
