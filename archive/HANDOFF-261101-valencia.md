# HANDOFF 2026-11-01: Valencia launches (Atlas Studio VLC 🇪🇸, 30 singles)

**What shipped:** a new studio, **Atlas Studio VLC**, the 57th, with 30 single-stop audio tours of Valencia and its
region and no walks.
- **Maker:** platform `dozent`, handle `atlas.vlc`, uuid5 `atlas-maker:vlc` = `3d291a7b-3e4f-5919-a5d6-da0c0d0701a5`.
- **Ids:** `atlas-tour:vlc:vlc-<slug>`, stops `atlas-stop:vlc:vlc-<slug>:1`.
- **Catalogue:** tours 2267 → 2297, makers 728 → 729, stops 2726 → 2756, cities 1077 → 1080 (Godella, Bétera,
  Benimantell; Valencia itself already had creator pins). Countries (104) and places (507) did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 30 folders numbered 01–30. Triage went to
the contributor first. They approved all 30, chose real town names for the three tours outside the city, chose
Valencian for the bilingual titles, and supplied Chapeau's street address and Genuí's farmhouse point.
- **Audio:** 102–120 s each. Not transcribed against the scripts.
- **Photos:** 129 delivered and shipped, all 1200×900 WebP, no byte duplicates. Gràffica has only a hero.
- **Bilingual `English | Valencian`** on 9. See `drafts/valencia-batch1/README.md`.

**Coordinates:** `check-coordinates.py --drop` found no GROSS and no northward bias (8/23 north, median −4.6 m).
**Three moved:**
- **Turia Gardens**, ~320 m from the riverbed onto the Pont de la Trinitat. The script's statue line was checked and is
  right.
- **Dos Aguas**, ~100 m south onto the palace.
- **Genuí**, onto the contributor's point.

**Architect tags (Job 5):** 16 new names on one line in each list. The full list, and who was deliberately left
untagged, is in the batch README.

**Places:** none created. One question went to Edward's board: Umbracle vs the City of Arts and Sciences pin (81 m,
part-vs-whole).

**gh-pages:** `a15ad77a`, one commit adding 159 files (30 audio, 129 images), built with plumbing. The diff was 159 A
only.

**Checks:**
- `validate-tours-mirror`: 0 errors, and no warnings on the new tours. Cabecera was given *Architecture* and Parc
  Central *History* to clear "no Theme tag".
- Filenames align (159).
- `spine-lookup`: 30 asked, 0 failed.
- No overlapping geofences among the 30.
