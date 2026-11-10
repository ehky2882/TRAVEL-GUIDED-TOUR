# HANDOFF 2026-11-10: Kuala Lumpur launches (Atlas Studio KUL 🇲🇾, 42 singles)

**What shipped:** a new studio, **Atlas Studio KUL**, the 62nd, with 42 single-stop audio tours of Kuala Lumpur and no walks.
- **Maker:** platform `dozent`, handle `atlas.kul`, uuid5 `atlas-maker:kul` = `70d7bfbd-188c-5712-b6d8-50c2a382d143`.
- **Catalogue:** tours 2421 → 2463, makers 779 → 780, stops 2880 → 2922. Cities (1098), countries (104) and places (513)
  did not move — creator pins already covered Kuala Lumpur.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 42 folders numbered 01–42. The triage went
to the contributor first; they approved it as proposed, chose the Malay/Chinese **mix** for bilingual titles, and
confirmed the photos are royalty-free.
- **Audio:** 94–132 s each. Not transcribed against the scripts.
- **Photos:** 174 delivered and shipped, all 1200×900 WebP, no byte duplicates.
- **Bilingual** on 19 of 42 (13 Malay, 6 simplified Chinese). Two Chinese names I first proposed in the triage were
  wrong and corrected by search before wiring: Yut Kee is 镒记 (not 日记), Ho Kow is 何九 (not 好姑).

**Coordinates:** none moved. `check-coordinates.py --drop` showed **no northward bias (23/39, median +2.4 m, p = 0.34)** —
unlike Fukuoka two days earlier. One GROSS (Pasar Seni) and four UNVERIFIABLE, all cleared by hand.

**Architect tags (Job 5):** 18 new names on one line in each list. `drafts/kuala-lumpur-batch1/README.md` lists them and
what was deliberately not tagged.

**Places:** none created. Three questions for Edward on `status/owner/kuala-lumpur-launch.md` (SAS Building 88 m,
Dayabumi 97 m, ILHAM Gallery vs Ilham Tower 52 m).

**gh-pages:** `0971de4f`, one commit adding 216 files (42 audio, 174 images), built with plumbing. The diff was 216 A only.

**Checks:** `validate-tours-mirror` 0 errors, 737 warnings (unchanged from before the batch) · filenames align (216) ·
one geofence overlap left on purpose (Ho Kow / Kwai Chai Hong, 19 m apart) · `spine-lookup` 42 asked, 0 failed ·
`join-places --max-move 100` nothing new.
