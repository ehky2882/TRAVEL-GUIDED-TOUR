# Tuscany batch 1: Atlas Studio SIE (3 singles) + Atlas Studio FLR (2 singles), wired 2026-11-26

Source: contributor drop (Dropbox). 5 `output <Name> <lat>, <lon>` folders, scripts numbered 50–53 and 80 (the
gap suggests more of this set may follow). Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3
(111–123 s, 589 s in all) and 4–7 photos at 1200×900 WebP (27 delivered, 27 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_tuscany.py` is the assembler
(`python3 -I wire_tuscany.py <unzipped drop> <stage dir>`), adapted from `drafts/veneto-batch1/tools/wire_veneto.py`.
Run it once only. Slugs carry a studio prefix: `audio/<code>-<slug>.mp3`, `images/<code>-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio SIE 🇮🇹 (Siena and the Tuscan hills), platform `dozent`, handle `atlas.sie`, uuid5
  `atlas-maker:sie` = `241cc7ba-f823-5e63-8e79-1c59948ce760`. The 71st studio (Trentino's TNO merged first as the 70th). Inserted after TNO.
- **Existing maker:** Atlas Studio FLR, `2ef7f356-9ba8-552f-a182-7ffbd7d78c7b`, for the two Florence-area tours.
- **Ids:** `atlas-tour:<code>:<code>-<slug>`, stops `atlas-stop:<code>:<code>-<slug>:1`.
- **gh-pages:** `5d0bf13`, one commit, 32 files added (5 audio + 27 images), A only.
- Triaged first. The contributor (arthur.yung) chose option (b): the two Florence-area tours to FLR, the other three
  to one new Siena studio; and asked for the Gamberaia pin to be moved onto the villa.

## Tours

| Studio | Title | City | Category | Radius |
|---|---|---|---|---|
| FLR | Villa Gamberaia | Florence (Settignano) | natureAndParks | 50 m |
| FLR | Sammezzano Castle \| Castello di Sammezzano | Reggello (Leccio) | architecture | 50 m |
| SIE | San Galgano Abbey \| Abbazia di San Galgano | Chiusdino | sacredSites | 50 m |
| SIE | Campatelli Tower House \| Torre e Casa Campatelli | San Gimignano | history | 25 m |
| SIE | The Little Theatre of Vetriano \| Teatrino di Vetriano | Pescaglia (Vetriano) | musicAndPerformance | 25 m |

Four new cities (Chiusdino, Reggello, San Gimignano, Pescaglia). Country `Italy`; `priceUSD` 0. Bilingual
`English | Italian` on 4 of 5; Villa Gamberaia keeps one name.

## Coordinates
`check-coordinates.py --drop`: no GROSS. Campatelli UNVERIFIABLE; 16 m from OSM's *Torre dei Campatelli*, kept.
Sammezzano 43 m, San Galgano 35 m, Vetriano 22 m, all kept. **Villa Gamberaia moved:** the supplied point was ~165 m
north of the villa, at the Via del Rossellino gate, while the script stands you on the grass walk beside the house;
it is now on OSM's *Villa Gamberaia* node (43.7793978, 11.3282381). BIAS: too few points to measure.

## Text
`longDescription` = hook + paragraph 3; `shortDescription` = the hook (all under 145 characters); captions written by
hand from each script's orientation paragraph. No text fixes.

## Architect tags (Job 5): 1 new name, one line in each list
Ferdinando Panciatichi Ximenes d'Aragona (designed Sammezzano himself, per the script). **Not** tagged: Ambrogio
Lorenzetti (painter), Antonio and Bernardo Rossellino (owned the Gamberaia land, did not build the villa), Zanobi Lapi
(had the villa built; not credited as architect), Jeanne Ghyka (garden design).

## Places
Nothing within 3 km of any of the five. `check-place-candidates` output identical to `main`'s; `join-places
--max-move 100` raised nothing. No questions for Edward.

## Not checked
Historical claims, dates and attributions are quoted from the scripts and were not independently verified.
Sammezzano is private and rarely open, and Vetriano is by booking; both scripts say so.
