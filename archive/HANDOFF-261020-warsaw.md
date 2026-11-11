# HANDOFF 2026-10-20: Warsaw launches (Atlas Studio WAW 🇵🇱, 34 singles)

**What shipped:** a new studio, **Atlas Studio WAW**, the 48th, with 34 single-stop audio tours of Warsaw and no walks.
- **Maker:** platform `dozent`, handle `atlas.waw`, uuid5 `atlas-maker:waw` = `cc43781a-ce30-5191-9658-75ade6fdb56e`.
- **Ids:** `atlas-tour:waw:<slug>`, stops `atlas-stop:waw:<slug>:1`; every slug starts `waw-`.
- **Catalogue:** tours 2069 → 2103, makers 702 → 703, stops 2528 → 2562. Cities, countries and places did not move.
  Creator pins and SovMod already covered Warsaw.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 34 folders. Triage went to the
contributor first, and they approved all 34. Script numbers 03, 10 and 27 are absent on purpose: those subjects are
already SovMod tours, or the contributor judged them not good enough.
- **Audio:** 97–130 s each. Not transcribed against the scripts.
- **Photos:** 125, no byte duplicates, all 1200×900 WebP. Eleven folders were numbered, and in those 01 leads. Cepelia
  Pavilion has only one photo, and seven tours have two. The contributor supplied them all, and no licence is recorded
  per image (on the owner's board).
- **Text:** `longDescription` = hook + paragraph 3, as in Vienna. `shortDescription` is cut at 145 characters.
  Captions were written by hand from each script's `Vantage:` header line.
- **Bilingual `English | Polish`** on 23 tours. Venues and names used as-is keep one name.
- **Geofence:** 40 m for venues; 50 m for the larger sites; 60 m for the Palace of Culture; 75 m for Za Żelazną Bramą,
  the Vistula Boulevards and Złota 44. Złota 44's script stands the listener on the Palace's west side and points them
  across the road.

**Coordinates.** `check-coordinates.py --drop` on the raw folders gave 18 UNVERIFIABLE, all because the folder names
escape Polish letters (`#U0119`). Re-run on a symlinked copy with decoded names, it gave 0 GROSS and 2 UNVERIFIABLE:
Bristol (checked by hand, on its corner) and the Boulevards (a promenade). Bias: 13/30 north, median −0.0 m, p = 0.58,
so no northward offset. **Neon Museum** is pinned inside the Palace of Culture. That is correct: it moved there from
Kamionek in August 2025.

**Architect tags (Job 5), 18 new names on one line in each list:** Enrico Marconi, Władysław Marconi, Juliusz
Dzierżanowski, JEMS Architekci, Zygmunt Stępiński, Lev Rudnev, Thomas Phifer, Stefan Szyller, Lahdelma & Mahlamäki,
Marek Budzyński, Zbigniew Badowski, Irena Bajerska, Piotr Wicha, Domenico Merlini, Józef Sigalin, Stanisław
Jankowski, Bohdan Lachert, Józef Szanajca. One existing tag was reused: Daniel Libeskind.
- **Rudnev** was tagged on the contributor's explicit instruction.
- **Left out on purpose:**
  - interior designers and restorers: Wojciechowski & Sojka (milk bar), Otto Wagner Jr. (Bristol interiors),
    Chołdzyński (Cepelia restoration);
  - Andrzej Milewski, co-designer at Cepelia;
  - the Za Żelazną Bramą competition team (Czyż, Furman, Skopiński);
  - Jan Knothe, at the MDM.

**Places, for Edward:** `status/owner/warsaw-launch.md`. The University Library (0 m) and the Palace of Culture
(11 m) each duplicate an existing creator pin, so both qualify. Neon Museum and Kulturalna are tenants of the Palace,
and Charlotte and Plan B are two venues 10 m apart: none of those is a place. `join-places --max-move 100` found
nothing new for Warsaw.

**gh-pages:** `659c1e96`, one commit adding 159 files (34 audio, 125 images), built with plumbing
(`GIT_NO_LAZY_FETCH=1`, `--missing-ok`, `--no-renames`). The diff was 159 A and nothing else.

**Checks:**
- `validate-tours-mirror`: 0 errors, and no warnings on the new tours.
- Filenames align (159).
- `spine-lookup`: 34 answered, 0 failed.
- `check-place-candidates` and `join-places`: as above.
