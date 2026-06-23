# "Montmartre" — multi-stop tour (audio pending)

Image-staged ahead of audio (2026-06-23). **Multi-stop** walk over the
Montmartre hill — Place des Abbesses up to Sacré-Cœur and the painters' square,
down to the Moulin Rouge. The real village vs. the souvenir of itself. Maker:
**Atlas Studio PAR** (🇫🇷 — *create when wiring; shared with the other Paris
tours*). Slug: `paris-montmartre`. **6 tracks** (intro = stop 0). Short but steep.

When audio lands: build one multi-stop `Tour`, 6 ordered geofenced `Stop`s, each
with `audioURL`, coordinate, `transcriptText` (non-TTS script here), `caption`
(first sentence), `imageURL` below. Set `heroImageURL`, **populate
`additionalImageURLs`** (gallery carousel — #233), `kind=multiStop`,
`walkingDistanceMeters≈1800`, `primaryCategory=culturalHeritage` (or `history`),
`city="Paris"`, `totalDurationSeconds`=sum of stop durations. Run validator.

- **Scripts:** `paris_montmartre_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. **All ship-safe
  (Unsplash/Pexels)** — logged in `IMAGE-CREDITS-paris-batch1.txt`.
- **Audio stems:** `paris_montmartre_multistop_NN_<name>_TTS.mp3`.

| Track | Stop | coord (lat, lon) | image |
|---|------|------------------|-------|
| 0 | Intro (the hill) | 48.8845, 2.3375 | `paris-montmartre_stop0.webp` |
| 1 | Place des Abbesses (Guimard métro) | 48.8844, 2.3380 | `paris-montmartre_stop1.webp` |
| 2 | The Wall of Love | 48.8841, 2.3383 | `paris-montmartre_stop2.webp` |
| 3 | Sacré-Cœur | 48.8867, 2.3431 | `paris-montmartre_stop3.webp` |
| 4 | Place du Tertre | 48.8865, 2.3406 | `paris-montmartre_stop4.webp` |
| 5 | Moulin Rouge | 48.8841, 2.3322 | `paris-montmartre_stop5.webp` |

**Tour hero:** `paris-montmartre_hero.webp` — Sacré-Cœur above the rooftops (Pexels).

Coords approximate landmark centroids; geofenced (~40 m). Catalog's prospective
**10th multi-stop tour** (after Paris Islands + Triumphal Way).

**Blocked on:** (1) the 6 narration MP3s; (2) the **Atlas Studio PAR** maker.
