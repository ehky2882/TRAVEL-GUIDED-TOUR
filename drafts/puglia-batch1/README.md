# Puglia batch 1: Atlas Studio BRI (5 singles), wired 2026-11-27

Source: contributor drop (Dropbox). 5 `output <Name> <lat>, <lon>` folders. Each holds `<NN>_<slug>_clean.txt` +
`_tts-safe.txt`, one MP3 (113–125 s) and 3–7 photos at 1200×900 WebP (25 delivered, 25 shipped).

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run. `tools/wire_puglia.py` is the assembler
(`python3 -I wire_puglia.py <unzipped drop> <stage dir>`), adapted from `drafts/sicily-batch1/tools/wire_sicily.py`.
Run it once only. Slugs carry the studio prefix: `audio/bri-<slug>.mp3`, `images/bri-<slug>_hero.webp`, `_2.webp`, …

- **New maker:** Atlas Studio BRI 🇮🇹 (Bari), platform `dozent`, handle `atlas.bri`, uuid5 `atlas-maker:bri` =
  `a3db3b82-d71b-5d58-ac11-0ce976e99588`. The 76th studio, inserted after PMO. One studio for all five Puglian sites,
  on the contributor's choice (arthur.yung: "BRI for all five"), rather than a regional code or a studio per town.
- **Ids:** `atlas-tour:bri:bri-<slug>`, stops `atlas-stop:bri:bri-<slug>:1`.
- **gh-pages:** `907e5a6`, one commit, 30 files added (5 audio + 25 images), A only.
- Triaged first; all 5 taken, none skipped.
- **Coordinates:** used as supplied. No GROSS. Four matched OSM within 15–38 m. Troia was UNVERIFIABLE automatically;
  checked by hand against the OSM footprint of the Concattedrale: the point sits ~5 m outside its north edge, i.e. in the
  street in front of it, as the script directs.
- **Photos:** the Petruzzelli folder's photos were delivered mostly named `teatro-margherita-bari_*`. They were checked
  by eye and are the Petruzzelli; the assembler renames by folder, so nothing collides with the Margherita's photos.
- **Architect tags (Job 5):** Francesco De Giglio (Teatro Margherita), Angelo Cicciomessere (Teatro Petruzzelli).
  Oderisio of Benevento (bronze doors at Troia) deliberately not tagged: he made the doors, not the building.
- **Place questions:** none. Nothing in the catalogue within 5 km of any of the five; the first content in Puglia.
- **Perishable lines in the audio:** none found.

## Tours

| Studio | Title | City | Category |
|---|---|---|---|
| BRI | Cerrate Abbey \| Abbazia di Santa Maria di Cerrate | Lecce | sacredSites |
| BRI | Troia Cathedral \| Cattedrale di Troia | Troia | sacredSites |
| BRI | Greek Fountain \| Fontana Greca | Gallipoli | visualArt |
| BRI | Teatro Margherita | Bari | architecture |
| BRI | Teatro Petruzzelli | Bari | musicAndPerformance |
