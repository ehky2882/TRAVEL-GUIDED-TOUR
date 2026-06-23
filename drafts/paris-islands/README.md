# "Paris Islands" — multi-stop tour (audio pending)

Image-staged ahead of audio (2026-06-23). **Multi-stop** walk along the two
Seine islands where Paris began — Île de la Cité (western prow → Notre-Dame)
then across to Île Saint-Louis. **Paris's first tour.** Maker: **Atlas Studio PAR**
(🇫🇷 — *does not exist yet; create it when wiring*). Slug: `paris-islands`.
**6 tracks** (intro = stop 0). ~1.4 km, flat.

When audio lands: build one multi-stop `Tour` with 6 ordered geofenced `Stop`s,
each with its own `audioURL`, coordinate, `transcriptText` (the non-TTS display
script here), `caption` (first sentence), and `imageURL` below. Set tour
`heroImageURL`, **populate `additionalImageURLs`** (the detail-gallery carousel
reads that — empty array = empty gallery, the bug fixed in #233), `kind=multiStop`,
`walkingDistanceMeters≈1400`, `primaryCategory=history`, `city="Paris"`,
`totalDurationSeconds`=sum of stop durations. Run the validator.

- **Scripts here:** `paris_islands_multistop_NN_<name>.txt` (display →
  `transcriptText`) + `..._TTS.txt` (audio source).
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.
- **Audio filename stems** (owner records as): `paris_islands_multistop_NN_<name>_TTS.mp3`.
  Map each to the stop image slug below for the gh-pages `audio/<slug>.mp3` name.

| Track | Stop | coord (lat, lon) | image | audio slug |
|---|------|------------------|-------|-----------|
| 0 | Intro (the islands) | 48.8566, 2.3469 | `paris-islands_stop0.webp` (Pexels) | `paris-islands` *(intro → tour `introAudioURL`/stop0)* |
| 1 | Pont Neuf | 48.8570, 2.3412 | `paris-islands_stop1.webp` (Unsplash) | tbd |
| 2 | Conciergerie | 48.8559, 2.3458 | `paris-islands_stop2.webp` (Pexels) | tbd |
| 3 | Sainte-Chapelle | 48.8554, 2.3450 | `paris-islands_stop3.webp` (Unsplash) | tbd |
| 4 | Notre-Dame | 48.8530, 2.3499 | `paris-islands_stop4.webp` (Pexels) | tbd |
| 5 | Île Saint-Louis | 48.8517, 2.3570 | `paris-islands_stop5.webp` (Unsplash) | tbd |

**Tour hero:** `paris-islands_hero.webp` — Île de la Cité aerial.
**⚠ CC BY-SA 3.0** (Wikimedia, David.Monniaux) — owner kept it despite the
no-attribution-UI policy (2026-06-23). Credit logged in
`IMAGE-CREDITS-paris-batch1.txt` on `gh-pages`. All 6 stop images are
Unsplash/Pexels (no attribution required).

Coords are approximate landmark centroids; all stops geofenced (~40 m radius
suggested, matching the other walks). Catalog's prospective **8th multi-stop tour**.

**Blocked on:** (1) the 6 narration MP3s; (2) creating the **Atlas Studio PAR**
maker in `Tours.json` (shared with the 45 staged single-stop Paris tours on
`claude/paris-scripts-260622`).
