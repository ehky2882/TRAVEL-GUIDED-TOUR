# Piedmont batch 1: Atlas Studio PIE (5 singles), wired 2026-11-26

Source: contributor drop (Dropbox). 5 `output <Name> <lat>, <lon>` folders, scripts numbered 01–05. Each holds
`<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (116–142 s, 615 s in all) and 4–7 photos at 1200×900 WebP
(29 delivered, 29 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_piedmont.py` is the assembler
(`python3 -I wire_piedmont.py <unzipped drop> <stage dir>`), adapted from `drafts/trentino-batch1/tools/wire_trentino.py`.
Run it once only. Slugs carry the studio prefix: `audio/pie-<slug>.mp3`, `images/pie-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio PIE 🇮🇹 (Piemonte), platform `dozent`, handle `atlas.pie`, uuid5 `atlas-maker:pie` =
  `fbe4066b-2aa0-51ba-b03d-cd8cefe988be`. The 72nd studio. Inserted after SIE. One regional studio for five towns,
  none of them in Turin (27–117 km out), on the contributor's choice (arthur.yung), rather than under TRN.
- **Ids:** `atlas-tour:pie:pie-<slug>`, stops `atlas-stop:pie:pie-<slug>:1`.
- **gh-pages:** `c8c9ca7`, one commit, 34 files added (5 audio + 29 images), A only.
- Triaged first; all five taken, none skipped.

## Tours

| Title | City | Category | Radius |
|---|---|---|---|
| Manta Castle \| Castello della Manta | Manta | visualArt | 40 m |
| Masino Castle and Park \| Castello e Parco di Masino | Caravino | history | 60 m |
| The Enrico Collection at Villa Flecchia \| Collezione Enrico a Villa Flecchia | Magnano | visualArt | 30 m |
| Villa Taranto Botanical Gardens \| Giardini Botanici di Villa Taranto | Verbania | natureAndParks | 60 m |
| St Michael's Abbey \| Sacra di San Michele | Sant'Ambrogio di Torino | sacredSites | 50 m |

Five new cities. Country `Italy`; `priceUSD` 0. Bilingual `English | Italian` on all 5 (Sacra kept bilingual on the
contributor's word).

## Coordinates
`check-coordinates.py --drop`: no GROSS (Manta and Sacra 22 m). 3 UNVERIFIABLE, checked by name against OSM and kept:
Masino ~43 m from the castle node, Villa Flecchia ~25 m, Villa Taranto at the entrance on Via Vittorio Veneto (~300 m
from the garden's centroid), where the script stands you "just inside the gates". BIAS: too few points. No geofence
overlaps. Nothing in the catalogue within 5 km, so no place questions.

## Text
`longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand from each
script's orientation paragraph. No text fixes.

## Architect tags: none
No script credits a building to a named architect. Not tagged: the Master of the Manta Castle (painter), Niccolò
(sculptor, Zodiac Portal), Neil McEacharn (garden maker), and Piero Enrico, an architect, but neither the script nor
the FAI says he designed Villa Flecchia.
