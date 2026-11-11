# HANDOFF 2026-11-08: Fukuoka launches (Atlas Studio FUK 🇯🇵, 30 singles)

**What shipped:** a new studio, **Atlas Studio FUK**, the 61st, with 30 single-stop audio tours of Fukuoka (one in
Dazaifu) and no walks.
- **Maker:** platform `dozent`, handle `atlas.fuk`, uuid5 `atlas-maker:fuk` = `48d15959-59f6-59e0-9c22-9ee589f4a0f5`.
- **Catalogue:** tours 2390 → 2420, makers 760 → 761, stops 2849 → 2879, cities 1090 → 1091 (Dazaifu). Countries (104)
  and places (507) did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 30 folders numbered 01–30. The triage
went to the contributor first. They approved it as proposed, confirmed Ishimura Manseido's address
(2-1 Suzaki-machi, Hakata-ku) and asked for the three optional architect tags (Nihon Sekkei, Yasushi Kataoka,
Shigeru Uchida).
- **Audio:** 74–126 s each, 128 kbps. Not transcribed against the scripts.
- **Photos:** 112 delivered and shipped, all 1200×900 WebP, no byte duplicates.
- **Bilingual `English | 日本語`** on 27 of 30. See `drafts/fukuoka-batch1/README.md`.

**Coordinates:** one corrected (Ishimura Manseido, ~112 m north in the wrong chōme). `check-coordinates.py --drop`
showed the **northward bias still present (12/13 north, median +18.9 m, p = 0.0034)**, so upstream is not fixed.

**Architect tags (Job 5):** 14 new names on one line in each list. The README lists them, and what was not tagged.

**Places:** none created, and no new candidates involving the 30 tours.

**gh-pages:** `8f9eda08`, one commit adding 142 files (30 audio, 112 images), built with plumbing. The diff was 142 A only.

**Checks:** `validate-tours-mirror` 0 errors, 727 warnings (unchanged from before the batch) · filenames align (142) ·
no overlapping geofences among the 30 · `spine-lookup` 30 asked, 0 failed · `join-places --max-move 100` nothing new.

**Content notes:** three scripts carry lines that will date (Books Kubrick, Tenjin Business Center II, the
underground mall's 50th). Kushida Shrine has a hero only.
