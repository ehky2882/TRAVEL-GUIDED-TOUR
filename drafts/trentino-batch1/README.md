# Trentino batch 1: Atlas Studio TNO (6 singles), wired 2026-11-26

Source: contributor drop (Dropbox). 6 `<Name> <lat>, <lon>` folders (five prefixed `output`, Aula del Simonino not),
scripts numbered 22–26 plus 82. Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (101–126 s, 673 s in
all) and 3–6 photos at 1200×900 WebP (28 delivered, 28 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_trentino.py` is the assembler
(`python3 -I wire_trentino.py <unzipped drop> <stage dir>`), adapted from `drafts/veneto-batch1/tools/wire_veneto.py`.
Run it once only. Slugs carry the studio prefix: `audio/tno-<slug>.mp3`, `images/tno-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio TNO 🇮🇹 (Trento, with Rovereto and Avio down the Adige valley), platform `dozent`,
  handle `atlas.tno`, uuid5 `atlas-maker:tno` = `cda1160d-8001-5a71-9fb0-29888bc56bf0`. The 70th studio. Inserted
  after PDA. Code `TNO` because `TRN` is Turin and Trento has no IATA code (contributor's choice, arthur.yung).
- **Ids:** `atlas-tour:tno:tno-<slug>`, stops `atlas-stop:tno:tno-<slug>:1`.
- **gh-pages:** `a74a46a`, one commit, 34 files added (6 audio + 28 images), A only.
- Triaged first; all six taken, none skipped. One studio for all three towns, on the contributor's word.

## Tours

| Title | City | Category | Radius |
|---|---|---|---|
| Aula del Simonino | Trento | history | 25 m |
| Buonconsiglio Castle \| Castello del Buonconsiglio | Trento | history | 50 m |
| Piazza del Duomo, Trento | Trento | culturalHeritage | 50 m |
| MUSE Science Museum \| MUSE – Museo delle Scienze | Trento | architecture | 50 m |
| Mart \| Museo di arte moderna e contemporanea | Rovereto | visualArt | 30 m |
| Avio Castle \| Castello di Avio | Avio | history | 60 m |

Three new cities (Trento, Rovereto, Avio). Country `Italy`; `priceUSD` 0. Piazza del Duomo keeps ", Trento" to stay
distinct from Milan's Piazza del Duomo tour. Bilingual `English | Italian` on 4 of 6; Aula del Simonino and Piazza
del Duomo keep one name (used as-is in English).

## Coordinates
`check-coordinates.py --drop`: no GROSS. 2 UNVERIFIABLE, checked by name against OSM and kept: MUSE ~20 m, Aula del
Simonino 29 m from Via del Simonino's centre. Avio is 204 m from the castle's OSM point, at the gate where the script
stands you looking up the hill; Buonconsiglio 68 m back on Via Bernardo Clesio, as the script asks. BIAS: too few
points to measure. No geofence overlaps. Nothing in the catalogue within 3 km, so no place questions.

## Text
`longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand from each
script's orientation paragraph. No text fixes.

## Architect tags (Job 5): 1 new name, one line in each list
Adamo d'Arogno (master builder of Trento Cathedral from 1212). Renzo Piano (MUSE) and Mario Botta (Mart) already
existed. Not tagged: Giulio Andreolli (engineer), Giongo (sculptor of the fountain), Bernardo Cles (patron).
