# Florence batch 1: Atlas Studio FLR (34 singles), wired 2026-11-18

Source: contributor drop (Dropbox). 34 `output <Name> <lat>, <lon>` folders, scripts numbered 01–33 plus an unnumbered
Ponte Vecchio. Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (93–136 s, 3,831 s in all) and 2–8 photos
at 1200×900 WebP (164 delivered, 164 shipped, no byte duplicates).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_florence.py` is the assembler
(`python3 -I wire_florence.py <unzipped drop> <stage dir>`), adapted from `drafts/lyon-batch1/tools/wire_lyon.py`.
Run it once only. Slugs carry an **`flr-` prefix**: `audio/flr-<slug>.mp3`, `images/flr-<slug>_hero.webp`, `_2.webp`, …

- **Maker:** Atlas Studio FLR 🇮🇹, platform `dozent`, handle `atlas.flr`, uuid5 `atlas-maker:flr`
  = `2ef7f356-9ba8-552f-a182-7ffbd7d78c7b`. The 67th studio.
- **Ids:** `atlas-tour:flr:flr-<slug>`, stops `atlas-stop:flr:flr-<slug>:1`.
- **gh-pages:** `12351be`, one commit, 198 files added (34 audio + 164 images), A only.
- Triaged first. The contributor (arthur.yung) approved "add all 34, move laurenziana, skip piano".

## Coordinates
`check-coordinates.py --drop`: 0 GROSS. BIAS 11/20 north, median +1.8 m, p = 0.82, so no northward offset.
7 UNVERIFIABLE, checked by hand against their script addresses (Nominatim): AdAstra (Via del Campuccio 53) 15 m,
Setificio (Via Lorenzo Bartolini 4) 20 m, Guadagni (Piazza Santo Spirito 9) 9 m, Riva Lofts (Via Baccio Bandinelli 98)
15 m, Church of the Motorway (OSM amenity) 31 m, Ditta Artigianale (OSM node, Via dello Sprone 5r) 17 m. Giannini reads
136 m, but that is to the centroid of Piazza de' Pitti, and the shop is across the square.
**Moved (contributor OK):** Biblioteca Medicea Laurenziana, 84 m north-east across the basilica → 43.7744207, 11.2537735
(the OSM node *Biblioteca Medicea Laurenziana*, Piazza di San Lorenzo 9).

## Wiring
- Country `Italy`. City `Florence` on 33. **Campi Bisenzio** (Church of the Motorway) is a new city. `priceUSD` 0.
- Geofence 20–30 m for restaurants, bars, shops and hotels; 40–60 m for museums, bridges, the station, stadium and
  garden. Scuola del Cuoio and the Pazzi Chapel are 32 m apart, so both are 15 m. No overlaps.
- **Bilingual** `English | Italian` on 13 of 34: Officina Profumo-Farmaceutica, Laurenziana, Opera del Duomo, Museo
  Bardini, Chiostro dello Scalzo, SMN station, Stadio Franchi, Church of the Motorway, Pazzi Chapel, San Miniato,
  Ponte Santa Trinita, Giardino Bardini, Oblate. Venues, brands and names used as-is in English keep one.
- Text: `longDescription` = hook + paragraph 3; `shortDescription` cut at 145 characters; captions written by hand from
  each script's orientation paragraph.
- Tags added after the validator warned: *Venue* on the four workshops, *Art* on Giardino Bardini.

## Architect tags (Job 5): 13 new names, one line in each list
Michelangelo and Bartolomeo Ammannati (Laurenziana; Ammannati built the stair) · Filippo Brunelleschi (Pazzi) ·
Bartolomeo Ammannati (Santa Trinita) · Giovanni Michelucci (SMN station, Church of the Motorway, Ditta Artigianale's
building) · Pier Luigi Nervi (Stadio Franchi) · Michelozzo (Scuola del Cuoio's building) · Giuliano da Sangallo and
Il Cronaca (Palazzo Strozzi) · Adolfo Natalini (Opera del Duomo's 2015 museum) · Claudio Nardi (Riva Lofts) · Michele
Bönan (Hotel Lungarno interiors) · Francesco Maestrelli (AdAstra) · Pietro Comparini (Villa Cora exterior).
**Not** tagged: Renzo Piano on Le Murate ("involved in the scheme"; contributor: skip), Gaetano Baccani (AdAstra: the
neighbouring tower), Giuseppe Poggi (Villa Cora: the road), Brunelleschi on Oblate / Guadagni (only in view), Alberti
(Novecento: the basilica across the square).

## Places — for Edward, nothing created or joined
`status/owner/place-florence.md`: Laurentian Library (0 m, @historianaisha), Ponte Vecchio (7 m, @hereinnyc), Trattoria
Sostanza (27 m, @nocrumbsleft). `join-places.py --max-move 100` raised nothing new.

## Not checked
Historical claims, dates and awards are quoted from the scripts and were not independently verified. Ditta
Artigianale's building being by Michelucci comes from the script.
