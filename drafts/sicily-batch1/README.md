# Sicily batch 1: Atlas Studio PMO (6 singles), wired 2026-11-27

Source: contributor drop (Dropbox). 6 `output <Name> <lat>, <lon>` folders. Each holds `<NN>_<slug>_clean.txt` +
`_tts-safe.txt`, one MP3 (110–127 s) and 3–4 photos at 1200×900 WebP (19 delivered, 19 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_sicily.py` is the assembler
(`python3 -I wire_sicily.py <unzipped drop> <stage dir>`), adapted from `drafts/lombardy-batch1/tools/wire_lombardy.py`.
Run it once only. Slugs carry the studio prefix: `audio/pmo-<slug>.mp3`, `images/pmo-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio PMO 🇮🇹 (Palermo), platform `dozent`, handle `atlas.pmo`, uuid5 `atlas-maker:pmo` =
  `1914b9e0-1387-5337-8c9b-5fceb1b26df3`. The 75th studio, inserted after LOM. One studio for all six Sicilian sites,
  on the contributor's choice (arthur.yung: "PMO for all six"), rather than a studio per town.
- **Ids:** `atlas-tour:pmo:pmo-<slug>`, stops `atlas-stop:pmo:pmo-<slug>:1`.
- **gh-pages:** `77756df`, one commit, 25 files added (6 audio + 19 images), A only.
- Triaged first; all 6 taken, none skipped.
- **Coordinates:** used as supplied. No GROSS. Segesta, Kolymbethra and Pantelleria were UNVERIFIABLE automatically and
  checked by hand against the OSM node by name: 28 m, 37 m and 24 m respectively.
- **Architect tags (Job 5):** Carlo Sada, Andrea Scala (Teatro Massimo Bellini). Patricolo (restorer of San Giovanni)
  and Camilliani (sculptor of the fountain) deliberately not tagged.
- **Perishable line left in the audio:** Teatro Massimo Bellini says it is "having major safety and restoration work
  during twenty twenty-six". Flagged to the contributor; will date in 2027. Fixing it means re-recording.

## Tours

| Studio | Title | City | Category |
|---|---|---|---|
| PMO | Pretoria Fountain \| Fontana Pretoria | Palermo | visualArt |
| PMO | San Giovanni degli Eremiti | Palermo | sacredSites |
| PMO | Temple of Segesta \| Tempio di Segesta | Calatafimi-Segesta | history |
| PMO | Teatro Massimo Bellini | Catania | musicAndPerformance |
| PMO | Kolymbethra Garden \| Giardino della Kolymbethra | Agrigento | natureAndParks |
| PMO | Donnafugata Pantelleria Garden \| Giardino Pantesco Donnafugata | Pantelleria | hiddenGems |
