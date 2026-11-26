# Lombardy batch 1: Atlas Studio LOM (16 singles) + Atlas Studio MIL (+3), wired 2026-11-26

Source: contributor drop (Dropbox). 19 `output <Name> <lat>, <lon>` folders (one, Rocca di Lonato, carried only the
coordinates). Each holds `<NN>_<slug>_clean.txt` + `_tts-safe.txt`, one MP3 (104–128 s) and 3–8 photos at 1200×900
WebP (95 delivered, 95 shipped; every hero checked by eye).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_lombardy.py` is the assembler
(`python3 -I wire_lombardy.py <unzipped drop> <stage dir>`), adapted from `drafts/piedmont-batch1/tools/wire_piedmont.py`.
Run it once only. Slugs carry the studio prefix: `audio/lom-<slug>.mp3` / `mil-<slug>.mp3`, `images/<same>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio LOM 🇮🇹 (Lombardia), platform `dozent`, handle `atlas.lom`, uuid5 `atlas-maker:lom` =
  `0050f2e3-ec73-5205-9eaa-7ab9c795f79a`. The 74th studio. Inserted after PIE. One regional studio for 15 towns, on the
  contributor's choice (arthur.yung: "MIL + LOM"), rather than a studio per city.
- **Atlas Studio MIL** (existing) takes the three in Milan and Segrate.
- **Ids:** `atlas-tour:<code>:<code>-<slug>`, stops `atlas-stop:<code>:<code>-<slug>:1`.
- **gh-pages:** `6e2ca5e`, one commit, 114 files added (19 audio + 95 images), A only.
- Triaged first; all 19 taken, none skipped.

## Tours

| Studio | Title | City | Category |
|---|---|---|---|
| MIL | Villa Necchi Campiglio | Milan | architecture |
| MIL | San Siro Racecourse and Leonardo's Horse \| Ippodromo San Siro e il Cavallo di Leonardo | Milan | visualArt |
| MIL | Palazzo Mondadori | Segrate | architecture |
| LOM | Villa del Balbianello | Tremezzina | natureAndParks |
| LOM | Villa Carlotta | Tremezzina | visualArt |
| LOM | La Velarca | Tremezzina | architecture |
| LOM | Villa Fogazzaro Roi | Valsolda | literature |
| LOM | Buco del Piombo | Erba | natureAndParks |
| LOM | Villa Panza and the Panza Collection \| Villa e Collezione Panza | Varese | visualArt |
| LOM | Villa Della Porta Bozzolo | Casalzuigno | history |
| LOM | Torba Monastery \| Monastero di Torba | Gornate Olona | sacredSites |
| LOM | The Macchi House and Shop \| Casa ed Emporio Macchi | Morazzone | hiddenGems |
| LOM | Palazzo Moroni | Bergamo | visualArt |
| LOM | San Michele Bridge \| Ponte San Michele | Paderno d'Adda | architecture |
| LOM | Leonardo's Ferry \| Traghetto di Leonardo | Imbersago | history |
| LOM | Royal Villa of Monza \| Villa Reale di Monza | Monza | history |
| LOM | Grumello Castle \| Castel Grumello | Montagna in Valtellina | history |
| LOM | The Old Newsstand \| Antica Edicola dei Giornali | Mantua | hiddenGems |
| LOM | Lonato Fortress and the Podestà's House \| Rocca di Lonato e Casa del Podestà | Lonato del Garda | history |

15 new cities (all but Milan). Country `Italy`; `priceUSD` 0. Bilingual `English | Italian` on 10 of 19 (9 LOM, 1 MIL) where the names
differ; names used as-is in English keep one. Balbianello, Carlotta and Velarca are listed under Tremezzina, the merged
comune that now holds Lenno, Tremezzo and Ossuccio.

## Coordinates
`check-coordinates.py --drop`: no GROSS. 6 UNVERIFIABLE, checked by name against OSM: Velarca 54 m (houseboat node),
Cavallo di Leonardo 15 m, Villa Panza 77 m, Piazza Canossa 23 m; the Imbersago landing has no OSM node and sits on the
Imbersago bank as the script says. Three moved onto their subject on the contributor's OK, to the OSM node by name:
**Palazzo Mondadori** 272 m (was across the lake) → Palazzo A; **Rocca di Lonato** 160 m (was at the Casa del Podestà)
→ the castle; **Buco del Piombo** 104 m → the cave entrance. BIAS: 12/15 north, median +11.8 m, n too small to call.
No geofence overlaps.

## Architect tags (Job 5)
7 new names: Piero Portaluppi and Tomaso Buzzi (Villa Necchi), BBPR (La Velarca), Paolo Vietti-Violi (San Siro
racecourse), Pietro Porcinai (Mondadori park), Luigi Canonica (enlarged Villa Panza), Jules Röthlisberger (Ponte San
Michele). Existing: Oscar Niemeyer (Mondadori), Giuseppe Piermarini (Monza). Not tagged: Mario Botta (only the Torba
altar), Antonio Tagliaferri (only restored the Casa del Podestà). Vietti-Violi, Porcinai and Canonica on the
contributor's word ("all tags in").

## Place question (for Edward)
Villa Necchi Campiglio: the new MIL tour sits 36 m from the existing @__dreamspaces pin of the same name. Not joined.
