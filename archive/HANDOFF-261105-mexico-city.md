# HANDOFF 2026-11-05: Mexico City launches (Atlas Studio MEX 🇲🇽, 35 singles)

**What shipped:** a new studio, **Atlas Studio MEX**, the 60th, with 35 single-stop audio tours of Mexico City and no walks.
- **Maker:** platform `dozent`, handle `atlas.mex`, uuid5 `atlas-maker:mex` = `04e05651-d6d0-514e-9724-ccffca65d17f`.
- **Catalogue:** tours 2355 → 2390, makers 731 → 732, stops 2814 → 2849. Cities (1081), countries (104) and places
  (507) did not move: 12 creator pins already covered Mexico City.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 35 folders numbered 01–36 (19 absent).
The triage went to the contributor first. They approved everything as proposed, asked for Naso not to be tagged,
accepted the thin photo sets (Carla Fernández has one photo; El Micky, El Turix and Sandra Weil have two each), and
said overlaps with creator pins are normal. That last point was left to Edward (see below).
- **Audio:** 96–121 s each. Not transcribed against the scripts.
- **Photos:** 164 delivered, 163 shipped, all 1200×900 WebP. One byte duplicate (LAGO/Chapultepec aerial) was kept for the park only.
- **Bilingual `English | Español`** on 8. See `drafts/mexico-city-batch1/README.md`.

**Coordinates:** four corrected (LAGO ~4 km, Issi ~770 m, UNAM ~700 m, Chapultepec ~380 m). Sources are in the
README. `check-coordinates.py --drop` showed no directional bias (median +9.7 m, p = 0.28).

**Architect tags (Job 5):** 14 new names on one line in each list. The README lists them, and what was not tagged.

**Places:** none created. Vasconcelos and Tamayo (same name as existing pins, 29 m / 26 m) and the Tláloc/Anthropology
part-vs-whole question are on Edward's board (`status/owner/mexico-city-launch.md`).

**gh-pages:** `d344ada9`, one commit adding 198 files (35 audio, 163 images), built with plumbing. The diff was 198 A only.

**Checks:** `validate-tours-mirror` 0 errors, 718 warnings (unchanged from before the batch) · filenames align (198) ·
no overlapping geofences among the 35 · no byte duplicates in the stage · `spine-lookup` 35 asked, 0 failed ·
`join-places --max-move 100` nothing new.

**Content notes (audio already recorded):** Issi's founder is "Isabella Romero" in the script, but "Isabella Romo" per
Quién and OpenTable. El Califa's May 2026 star withdrawal was not verified. Lamartine "opened in 2026" will date.
