# HANDOFF 2026-10-29: Turin launches (Atlas Studio TRN 🇮🇹, 29 singles)

**What shipped:** a new studio, **Atlas Studio TRN**, the 55th, with 29 single-stop audio tours of Turin and no walks.
- **Maker:** platform `dozent`, handle `atlas.trn`, uuid5 `atlas-maker:trn` = `dbf1ef30-789b-5776-abd3-5b220023c9df`.
- **Ids:** `atlas-tour:trn:trn-<slug>`, stops `atlas-stop:trn:trn-<slug>:1`.
- **Catalogue:** tours 2216 → 2245, makers 725 → 726, stops 2675 → 2704, cities 1025 → 1026 (on top of #1163) (Turin is new: nothing in
  the catalogue sat within 10 km of it). Countries (103) and places (507) did not move.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 29 folders numbered 01–30. Triage went to
the contributor first; they approved all 29, said No. 18 was left out deliberately as not a good tour, confirmed
L'ibrida Bottega is still trading (one web listing had mentioned a closing sale), accepted Piano 35 despite it sitting
6.5 m from the skyscraper tour, and supplied Marco Polo's address.
- **Audio:** 96–127 s each. Not transcribed against the scripts.
- **Photos:** 113 delivered and shipped, all 1200×900 WebP, no byte duplicates. Floris House has a hero only;
  Gilibert and Luxemburg have two photos each.
- **Text:** `longDescription` = hook + paragraph 3, as in Naples; `shortDescription` cut at 145 characters; `[beat]`
  stripped from the transcript. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Italian`** on 7 (Balôn, Sandretto Re Rebaudengo, Intesa Sanpaolo, Museo Egizio, Risorgimento,
  Mountain Museum, Pfatisch). Titles tidied from folder names (see `drafts/turin-batch1/README.md`).

**Coordinates.** `check-coordinates.py --drop`: 2 GROSS, both false (the geocoder matched same-named businesses 20 km
out of town, Gelateria Pepino in Moriondo and Ferrero1947 in Poirino), 14 UNVERIFIABLE, mostly because the mangled
accents broke the search. Re-checked by street address and name: 25 of 29 within ~40 m. Madamadorè 76 m and Pavia &
Pavia 70 m (square centroid) are on the right street/square; Balôn and Porta Palazzo are a street and a square.
**Marco Polo was wrong by 295 m** (the point was on Via Revel); moved to OSM's point for Corso Vittorio Emanuele II 86
on the contributor's address. Bias: 5/11 north, median −0.4 m, p = 1 — no sign of the Barcelona/Milan offset.

**Architect tags (Job 5), 6 new names on one line in each list:** Alessandro Antonelli (Mole, Casa Scaccabarozzi),
Carlo Mollino (Casa Mollino, his own interior), Claudio Silvestrin (Fondazione Sandretto), Guarino Guarini (Palazzo
Carignano → Risorgimento museum), Pietro Fenoglio (the Via Sacchi building housing Pfatisch, per the script), Filippo
Juvarra (Piazza della Repubblica → Porta Palazzo). Existing tag used: Renzo Piano (skyscraper). **Not** tagged: Dante
Ferretti (exhibition design), the Bouroullecs (a counter), Brondi & Rainò (interiors), Antonio Vandone (café fit-out),
Jeannot Cerutti (shop conversion; borderline, left out), and Renzo Piano on Piano 35 (a bar, not the building).

**Places:** none. `check-place-candidates` adds one TIGHT pair, Intesa Sanpaolo Skyscraper ↔ Piano 35 (6.5 m): a
tenant is not the site, so not a place. `join-places --max-move 100` found nothing in Turin.

**gh-pages:** `693e529e`, one commit adding 142 files (29 audio, 113 images), built with plumbing. Diff was 142 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (142) ·
`spine-lookup` 29 answered, 0 failed.
