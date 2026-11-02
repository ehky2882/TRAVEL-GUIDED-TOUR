# HANDOFF 2026-11-02: Mecca launches (Atlas Studio MAK 🇸🇦, 29 singles)

**What shipped:** a new studio, **Atlas Studio MAK**, the 58th, with 29 single-stop audio tours of Mecca and no walks.
- **Maker:** platform `dozent`, handle `atlas.mak`, uuid5 `atlas-maker:mak` = `cc7affff-e23b-5f3e-9e67-1b2c284be680`.
- **Ids:** `atlas-tour:mak:mak-<slug>`, stops `atlas-stop:mak:mak-<slug>:1`.
- **Catalogue:** tours 2297 → 2326, makers 729 → 730, stops 2756 → 2785. Cities (1080), countries (104) and places
  (507) did not move: the existing *Abraj Al Bait* creator pin already covered Mecca and Saudi Arabia.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 29 folders with scripts numbered 01–37.
Triage went to the contributor first. They chose the code MAK, confirmed that 04–07, 09, 20, 35 and 36 were dropped
upstream, and approved all 29 as proposed.
- **Audio:** 75–123 s each. Not transcribed against the scripts.
- **Photos:** 80 delivered and shipped, all 1200×900 WebP, no byte duplicates. Six tours have only a hero.
- **Bilingual `English | العربية`** on 24. See `drafts/mecca-batch1/README.md`.

**Coordinates:** `check-coordinates.py --drop` found no northward bias (7/22 north, median −0.1 m). Its one GROSS (the
Kaaba) is a false alarm, a hotel name match. None was moved. Bay'ah Mosque was confirmed against OSM by hand, and
Al Romansiah by its district and nearby hotel listings.

**Architect tags (Job 5):** 3 new names on one line in each list: Mohamed Kamal Ismail, Dar Al-Handasah, Samir Elabd.

**Places:** none created. Two part-vs-whole questions are on Edward's board (`status/owner/mecca-launch.md`), together
with a note about haram access for non-Muslim visitors and the photo licences.

**gh-pages:** `8a8a7911`, one commit adding 109 files (29 audio, 80 images), built with plumbing. The diff was 109 A
only. A first attempt failed before anything was pushed (`git -C` resolved relative paths against the repo); use
absolute source paths with `hash-object`.

**Checks:**
- `validate-tours-mirror`: 0 errors and 718 warnings, the same count as before the batch. The five "no Place type
  tag" warnings were cleared with Park (mountains, cave) and Monument (cemetery, well), following existing tours.
- Filenames align (109).
- `spine-lookup`: 29 asked, 0 failed.
- No overlapping geofences among the 29.
