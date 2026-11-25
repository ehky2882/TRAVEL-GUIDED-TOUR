# Veneto batch 1: Atlas Studio PDA (8 singles) + Atlas Studio VCE (3 singles), wired 2026-11-25

Source: contributor drop (Dropbox). 11 `output <Name> <lat>, <lon>` folders (one name delivered garbled as
`Caff#U00e8 Pedrocchi`), scripts numbered 32–43 plus 83. Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one
MP3 (105–129 s, 1,308 s in all) and 1–8 photos at 1200×900 WebP (51 delivered, 51 shipped; Ca' Giustinian has a
hero only).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_veneto.py` is the assembler
(`python3 -I wire_veneto.py <unzipped drop> <stage dir>`), adapted from `drafts/venice-batch1/tools/wire_venice.py`.
Run it once only. Slugs carry a studio prefix: `audio/vce-<slug>.mp3` / `audio/pda-<slug>.mp3`, and the same for
`images/…_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio PDA 🇮🇹 (Padua and the Veneto mainland), platform `dozent`, handle `atlas.pda`, uuid5
  `atlas-maker:pda` = `fc25cc81-0f58-5f8a-81ee-446dd2981198`. The 69th studio. Inserted after VCE.
- **Existing maker:** Atlas Studio VCE, `e5956ad8-b758-595b-a7e9-364b921c7439`, for the three Venice tours.
- **Ids:** `atlas-tour:<code>:<code>-<slug>`, stops `atlas-stop:<code>:<code>-<slug>:1`.
- **gh-pages:** `46a1596`, one commit, 62 files added (11 audio + 51 images), A only.
- Triaged first. The contributor (arthur.yung) chose option (a): Venice tours to VCE, the other eight to one new
  Padua studio.

## Tours

| Studio | Title | City | Category |
|---|---|---|---|
| VCE | Doge's Palace \| Palazzo Ducale | Venice | history |
| VCE | Ca' Pesaro \| Galleria Internazionale d'Arte Moderna | Venice | visualArt |
| VCE | Ca' Giustinian | Venice | history |
| PDA | Caffè Pedrocchi | Padua | foodAndDrink |
| PDA | Palazzo della Ragione | Padua | architecture |
| PDA | Petrarch's House \| Casa del Petrarca | Arquà Petrarca | literature |
| PDA | Villa dei Vescovi | Torreglia (Luvigliano) | architecture |
| PDA | Villa Pisani | Stra | architecture |
| PDA | Bassano's Old Bridge \| Ponte Vecchio | Bassano del Grappa | architecture |
| PDA | Madonna della Corona Sanctuary \| Santuario della Madonna della Corona | Ferrara di Monte Baldo | sacredSites |
| PDA | Monte Fontana Secca | Seren del Grappa | natureAndParks |

Six new cities (Arquà Petrarca, Torreglia, Stra, Bassano del Grappa, Ferrara di Monte Baldo, Seren del Grappa);
Padua already existed. Country `Italy`; `priceUSD` 0. Bassano's title is worded to stay distinct from the Florence
Ponte Vecchio tour.

## Coordinates
`check-coordinates.py --drop`: no GROSS. 4 UNVERIFIABLE, each checked by name against OSM and kept as supplied:
Ca' Pesaro 31 m, Caffè Pedrocchi 26 m, Villa Pisani 16 m (the tool matched a namesake 50 km away), and Ca'
Giustinian (the geocoder returned Ca' Foscari; the supplied point is at San Marco Vallaresso, where the script stands
you). Monte Fontana Secca's 1,073 m was to another feature; it is 33 m from OSM's Malga Fontana Secca.
BIAS 7/10 north, median +10.9 m, p = 0.34: too few points to call, consistent with the upstream offset.

## Wiring
- Geofence 25 m Pedrocchi and Petrarca; 30 m Ca' Pesaro and Ca' Giustinian; 40 m Ragione, Vescovi, Bassano bridge;
  50 m Doge's Palace, Villa Pisani, Madonna della Corona; 60 m Monte Fontana Secca (open pasture). No overlaps.
- **Bilingual** `English | Italian` on 5 of 11. Ca' Giustinian, Caffè Pedrocchi, Palazzo della Ragione, Villa Pisani,
  Villa dei Vescovi and Monte Fontana Secca keep one name (used as-is in English).
- Text: `longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand
  from each script's orientation paragraph. No text fixes.

## Architect tags (Job 5): 9 new names, one line in each list
Giovanni Bon and Bartolomeo Bon (Porta della Carta) · Antonio Gaspari (finished Ca' Pesaro; Longhena already a tag) ·
Giuseppe Jappelli (Pedrocchi) · Giovanni degli Eremitani (the 1306–09 hall and roof of the Ragione) · Giovanni Maria
Falconetto and Andrea da Valle (Villa dei Vescovi) · Girolamo Frigimelica and Francesco Maria Preti (Villa Pisani).
Palladio (already a tag) on the Bassano bridge.
**Not** tagged: Giulio Romano (Vescovi, "almost certainly had a hand"), Tiepolo (painter, Villa Pisani ceiling).

## Places — for Edward, nothing created or joined
`status/owner/place-doges-palace.md`: the new Doge's Palace tour is 4 m from the TikTok pin *The Doge's Palace*
(@hereinnyc). `join-places.py --max-move 100` raised nothing from this batch.

## Not checked
Historical claims, dates and attributions are quoted from the scripts and were not independently verified.
