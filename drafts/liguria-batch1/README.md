# Liguria batch 1: Atlas Studio GOA (6 singles), wired 2026-11-26

Source: contributor drop (Dropbox). 6 `output <Name> <lat>, <lon>` folders, scripts numbered 44–49 (continuing the
series the Tuscany batch's 50–53 and 80 belong to). One folder (Villa Rezzola) carried coordinates only, no name; the
name came from its files. Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (94–114 s) and 2–7 photos at
1200×900 WebP (27 delivered, 27 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_liguria.py` is the assembler
(`python3 -I wire_liguria.py <unzipped drop> <stage dir>`), adapted from `drafts/tuscany-batch1/tools/wire_tuscany.py`.
Run it once only. Slugs carry the studio prefix: `audio/goa-<slug>.mp3`, `images/goa-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio GOA 🇮🇹 (Genoa and the Ligurian coast), platform `dozent`, handle `atlas.goa`, uuid5
  `atlas-maker:goa` = `fd5fca23-af5f-5a67-a9d1-4268e5535354`. The 72nd studio. Inserted after SIE.
- **Ids:** `atlas-tour:goa:goa-<slug>`, stops `atlas-stop:goa:goa-<slug>:1`.
- **gh-pages:** `7db9ac2`, one commit, 33 files added (6 audio + 27 images), A only.
- Triaged first. The contributor (arthur.yung) chose one studio, GOA, for all six; asked for both coordinate moves
  below; and kept Antica Barberia Giacalone to one name.

## Tours

| Title | City | Category | Radius |
|---|---|---|---|
| Villa Rezzola | Lerici | natureAndParks | 50 m |
| San Fruttuoso Abbey \| Abbazia di San Fruttuoso | Camogli | sacredSites | 50 m |
| Antica Barberia Giacalone | Genoa | hiddenGems | 25 m |
| Casa Carbone | Lavagna | history | 25 m |
| The Laura House and Collection \| Casa e Collezione Laura | Ospedaletti | visualArt | 25 m |
| Tellaro | Lerici | hiddenGems | 50 m |

Five new cities (Genoa, Lerici, Camogli, Lavagna, Ospedaletti). Country `Italy`; `priceUSD` 0. Bilingual
`English | Italian` on 2 of 6; the other four are names used as-is.

## Coordinates
`check-coordinates.py --drop`: no GROSS. Giacalone and Rezzola UNVERIFIABLE; Giacalone ~25 m from OSM's Vico
Caprettari, kept. Casa Laura 11 m, Casa Carbone 16 m, San Fruttuoso 16 m, all kept. **Moved, on the contributor's
instruction:**
- **Tellaro:** supplied point ~280 m up Via Fiascherino (the road in); the script stands you at the church of San
  Giorgio. Now on OSM's *Chiesa di San Giorgio* (44.0575476, 9.9292254).
- **Villa Rezzola:** supplied point ~105 m away on Via G. Rinaldi; the script starts on the terrace below the villa.
  Now on OSM's *Villa Rezzola* building (44.0859942, 9.9098111).

BIAS: too few points to measure.

## Text
`longDescription` = hook + paragraph 3; `shortDescription` = the hook (all under 145 characters); captions written by
hand from each script's orientation paragraph. No text fixes.

## Architect tags
None. No script credits an architect: the Cochranes (Rezzola) and the Doria (San Fruttuoso's tower) were owners and
patrons, and Italo Giacalone was the barber who redecorated his shop. No tour carries *Designed by a Master*.

## Places
Nothing in the catalogue within 3 km of any of the six. `check-place-candidates` and `join-places --max-move 100`
raised nothing involving them. No questions for Edward.

## Not checked
Historical claims, dates and attributions are quoted from the scripts and were not independently verified.
Villa Rezzola's "the house itself is still being restored" will date. Casa Carbone and Casa Laura are seasonal;
both scripts say to check before visiting.
