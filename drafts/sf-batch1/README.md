# San Francisco — single-stop tours, batch 1 (audio pending)

Image-staged ahead of audio (2026-06-24). **New city: San Francisco** 🌉 — the
first SF tours. All **single-stop**, geofenced. Maker: **Atlas Studio SFO**
(🇺🇸 — *does not exist yet; create it in `Tours.json` when wiring the first SF
tour; shared by all SF tours, like Atlas Studio PAR for Paris*).

This is a **partial batch** — owner is uploading more SF tours (numbering has
gaps: 01, 03, 05, 06 so far; 02, 04, … to come).

When audio lands per tour: build a single-stop `Tour` (`kind=single`, 1 stop),
`heroImageURL` + `additionalImageURLs` (gallery), `caption`=first sentence,
`transcriptText`=the non-TTS script here, `city="San Francisco"`. Run validator.

- **Scripts:** `sf_NN_<name>.txt` (display) + `..._TTS.txt` (audio source).
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. **All ship-safe
  (Unsplash/Pexels/Pixabay) — no attribution.**
- **Audio:** owner records as `sf_NN_<name>_TTS.mp3`; map each to the image slug
  below → host on gh-pages as `audio/<slug>.mp3`.

| # | Tour | slug | coord (lat, lon) | suggested category | hero | gallery |
|---|------|------|------------------|--------------------|------|---------|
| 01 | Ferry Building | `ferry-building` | 37.7955, -122.3937 | culturalHeritage | F1 (full building+plaza) | 4 (_2.._5) |
| 03 | Pier 39 Sea Lions | `pier-39-sea-lions` | 37.8088, -122.4098 | natureAndParks | P3 (sea lions on docks) | 4 (_2.._5) |
| 05 | Alcatraz | `alcatraz` | 37.8267, -122.4230 | history | A1 (island from the water) | 4 (_2.._5; _3 = cellblock interior) |
| 06 | Coit Tower | `coit-tower` | 37.8024, -122.4058 | architecture | C1 (tower on Telegraph Hill) | 3 (_2.._4) |

Coords are approximate landmark centroids; geofence ~40 m. All image URLs live on
gh-pages (verified 200). Categories are suggestions — confirm at wire time.

**Blocked on:** (1) the narration MP3s; (2) the **Atlas Studio SFO** maker.
