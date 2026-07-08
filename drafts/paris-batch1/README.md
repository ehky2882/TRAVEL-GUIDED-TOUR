# Paris — batch 1 (tours 01–14), image-staged ahead of audio

Staged 2026-06-22. **14 single-stop Paris tours**, images on `gh-pages`, **audio pending**.
More Paris batches to follow (append here).

## Wiring (when audio lands)
1. **Create a new maker: Atlas Studio PAR** in `Tours.json` (Paris is the first new
   city/maker since HKG — no PAR maker exists yet). Give it a fresh UUID + 🇫🇷.
2. Add the 14 tours under PAR, single-stop, geofenced, with the staged image URLs
   (`https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/<slug>_hero.webp` + `_N.webp`),
   audio (`audio/<slug>.mp3`), looked-up coordinates, `transcriptText` from the
   display scripts here.
3. Validate; merge → auto-publishes to gh-pages (live, no build) per #212.

- **Scripts here:** `paris_NN_<slug>.txt` (display → `transcriptText`) + `..._TTS.txt` (audio source).
- **Audio slugs** = the image slugs below (NOT the script filename, which differs for #04/#14).
- CC BY-SA shots (Conciergerie interior, Palais-Royal) logged in `IMAGE-CREDITS-paris-batch1.txt` on `gh-pages`.

| # | Tour | slug | hero | gallery |
|---|------|------|------|---------|
| 01 | Notre-Dame de Paris | notre-dame | Unsplash/stock | 7 |
| 02 | Sainte-Chapelle | sainte-chapelle | owner paste (exterior) | 7 (interior) |
| 03 | Conciergerie | conciergerie | stock | 6 (incl. Wikimedia interior) |
| 04 | Île Saint-Louis | ile-saint-louis | stock | 3 |
| 05 | Louvre | louvre | stock | 7 |
| 06 | Musée de l'Orangerie | orangerie | owner paste (building) | 2 (incl. owner Water-Lilies) |
| 07 | Jardin des Tuileries | tuileries | stock | 7 |
| 08 | Place Vendôme | place-vendome | stock | 2 |
| 09 | Palais-Royal | palais-royal | Wikimedia | 2 |
| 10 | Arc de Triomphe | arc-de-triomphe | stock | 6 |
| 11 | Champs-Élysées | champs-elysees | stock | 7 |
| 12 | Place de la Concorde | place-de-la-concorde | stock | 6 |
| 13 | Grand Palais | grand-palais | stock | 6 |
| 14 | Pont Alexandre III / Petit Palais | pont-alexandre-iii | stock | 9 (bridge + 4 Petit Palais) |

Note: #14's script file is `paris_14_pont_alexandre_iii_petit_palais.txt`; its image/audio slug is `pont-alexandre-iii`.
