# Madrid — single-stop tours, batch 3 (audio pending)

Image-staged 2026-06-29. Continues the Madrid city build (see `madrid-batch1`,
`madrid-batch2`). All **single-stop**, geofenced, maker **Atlas Studio MAD**
(🇪🇸 — *does not exist yet; create it in `Tours.json` when wiring the first
Madrid tour; shared by all Madrid tours, like PAR/SFO*).

When audio lands per tour: single-stop `Tour` (`kind=single`, 1 stop),
`heroImageURL` + `additionalImageURLs` (gallery), `caption`=first sentence,
`transcriptText`=non-TTS script here, `city="Madrid"`. Run validator. Audio
`madrid_NN_<name>_TTS.mp3` → gh-pages `audio/<slug>.mp3`.

- **Scripts:** `madrid_NN_<name>.txt` (display) + `..._TTS.txt` (audio source).
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.
- **All images ship-safe** (Unsplash/Pexels — no attribution). Sourced via the
  pipeline (Gemini verify gate); owner picked hero + gallery by number.

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 07 | Catedral de la Almudena | `catedral-de-la-almudena` | 40.4158, -3.7144 | sacredSites | A1 (Uns) | 7 (_2.._8) |
| 08 | Plaza de Oriente & Teatro Real | `plaza-de-oriente` | 40.4180, -3.7108 | culturalHeritage | O3 (Pex) | 7 (_2.._8) |
| 11 | Plaza de España | `plaza-de-espana` | 40.4234, -3.7122 | culturalHeritage | E3 (Pex) | 2 (_2, _3) |
| 13 | Círculo de Bellas Artes | `circulo-de-bellas-artes` | 40.4186, -3.6962 | hiddenGems | C2 (Uns) | 3 (_2.._4) |

Coords approximate landmark centroids; geofence ~40 m. Categories owner-confirmed
defaults (Plaza de España could be `natureAndParks`; Círculo could be `visualArt`).

**Image pick map (owner, 2026-06-29):**
- Almudena — hero A1; gallery A3, A5, A6, A7, A9, A13, A12
- Plaza de Oriente — hero O3; gallery O2, O5, O6, O7, O8, O11, O13
- Plaza de España — hero E3; gallery E6, E7
- Círculo de Bellas Artes — hero C2; gallery C1, C5, C6

**Blocked on:** (1) narration MP3s; (2) the **Atlas Studio MAD** maker.
