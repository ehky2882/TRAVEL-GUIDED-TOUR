# HANDOFF 2026-11-11: Brasília launches (Atlas Studio BSB 🇧🇷, 31 singles)

**What shipped:** a new studio, **Atlas Studio BSB**, the 64th, with 31 single-stop audio tours of Brasília and no walks.
- **Maker:** platform `dozent`, handle `atlas.bsb`, uuid5 `atlas-maker:bsb` = `08918da7-8218-561a-b8ef-0b37907d4b87`.
- **Catalogue:** tours 2499 → 2530, makers 810 → 811, stops 2987 → 3018. Cities (1108), countries (104) and places (609)
  did not move — creator pins already covered Brasília.

**Source:** a Dropbox drop from the contributor (not the owner), 31 folders, scripts numbered 01–32 with no 03. Triage went to
the contributor first; they approved it as proposed, asked for the pins moved onto their subjects, and for Rocha and Campelo
to be tagged. Full wiring record: `drafts/brasilia-batch1/README.md`.
- **Audio:** 94–124 s each, 3,472 s. Not transcribed against the scripts.
- **Photos:** 124 delivered and shipped, all 1200×900 WebP, no byte duplicates.
- **Bilingual** on 20 of 31 (Portuguese).

**Coordinates:** 3 moved onto their buildings (SARAH 146 m, Teatro Nacional 103 m, Conic 99 m). Congress and Ponte JK were
proposed too but turned out already on their subjects — the triage's 150 m figures were to a fountain and to a bridge's
mid-point. 🔴 **The upstream northward bias is back (20/24, median +17 m, p = 0.0015)** after being absent from Kuala Lumpur.
⚠️ `check-coordinates.py --drop` cannot geocode `#Uxxxx`-escaped folder names (17 of 31 UNVERIFIABLE on the raw drop, 1 on a
decoded copy) — decode before running it.

**gh-pages:** `de2fc5f`, one commit adding 155 files (31 audio, 124 images), 155 A only. ⚠️ It sits on top of an **empty
commit `a5d6cfc`** pushed a minute earlier by a plumbing loop whose relative paths failed silently (tree identical to its
parent — verified — so nothing changed). Lesson: guard the push on the A count.

**Architect tags (Job 5):** 7 new names on one line in each list (README § Architect tags).

**Places:** none created. Five questions for Edward on `status/owner/place-brasilia.md`.

**Checks:** `validate-tours-mirror` 0 errors, 742 warnings (unchanged from before the batch) · filenames align (155) ·
no geofence overlaps · `spine-lookup` 31 asked, 0 failed · `join-places --max-move 100` nothing new.

**After the merge — the publish hung (2026-11-11 19:34 → 2026-11-12 00:00 UTC).** Publish run #421 (for #1187) failed its
gh-pages mirror step on a GitHub HTTP 502, and its **Supabase seed sat in "Apply seed" for 4 h 26 min** (normal today:
8½–15 min), holding the `publish-catalog` concurrency group, so run #422 queued behind it and nothing published. The
contributor asked why Brasília was not in the app; the database held 0 BSB rows and `catalog_snapshot_age` still read 18:33.
Cancelled #421 on the contributor's instruction; #422 (a newer `main`, which contains #1187) started at once and finished
green: seed 8½ min, mirror published, snapshot 00:08:53, **31 BSB rows live**. ⚠️ No cause found for the hang — the job log
is unavailable while a step runs, and the cancelled run's log was not read. If a seed runs past ~30 min, cancel it.
