# Madrid — single-stop tours, batch 4 (audio pending)

Image-staged 2026-06-29. Continues the Madrid city build (see `madrid-batch1..3`).
All **single-stop**, geofenced, maker **Atlas Studio MAD** (🇪🇸 — *create in
`Tours.json` when wiring the first Madrid tour; shared by all Madrid tours*).

When audio lands per tour: single-stop `Tour` (`kind=single`, 1 stop),
`heroImageURL` + `additionalImageURLs` (gallery), `caption`=first sentence,
`transcriptText`=non-TTS script here, `city="Madrid"`. Run validator. Audio
`madrid_NN_<name>_TTS.mp3` → gh-pages `audio/<slug>.mp3`.

- **Scripts:** `madrid_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. Sourced via the
  pipeline (Unsplash/Pexels/Pixabay → Gemini verify) + owner-supplied pastes.
- **All ship-safe or owner-supplied — no attribution needed this batch.**

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 27 | El Rastro | `el-rastro` | 40.4085, -3.7078 | culturalHeritage | R4 | 3 (_2 R3, _3 R1, _4 R8) |
| 31 | Malasaña / Plaza del Dos de Mayo | `plaza-del-dos-de-mayo` | 40.4259, -3.7038 | culturalHeritage | owner (arch + Daoíz y Velarde) | none (hero-only, owner choice) |
| 32 | Chueca / Mercado de San Antón | `mercado-de-san-anton` | 40.4221, -3.6975 | culturalHeritage | H8 | 2 (_2 H7, _3 owner Mercado) |
| 33 | Plaza de Colón | `plaza-de-colon` | 40.4250, -3.6903 | culturalHeritage | L3 | 3 (_2 L8, _3 L2, _4 owner flag+discovery) |

Coords approximate landmark centroids; geofence ~40 m.

**Image pick map (owner, 2026-06-29):**
- El Rastro — hero R4; gallery R3, R1, R8 (all ship-safe)
- Malasaña — hero owner-supplied (Plaza del Dos de Mayo arch + monument); no gallery
- Chueca — hero H8, gallery H7 (ship-safe) + owner-supplied Mercado de San Antón facade
- Plaza de Colón — hero L3, gallery L8 + L2 (ship-safe) + owner-supplied giant-flag & Jardines del Descubrimiento shot

Notes: the Garden of Discovery (Jardines del Descubrimiento) and the Plaza del
Dos de Mayo arch monument are thin in stock libraries — owner supplied those
shots directly. Plaza de Santa Ana (batch 3 #26) was the same.

**Blocked on:** (1) narration MP3s; (2) the **Atlas Studio MAD** maker.
