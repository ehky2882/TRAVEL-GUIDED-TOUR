# "The Left Bank" (Latin Quarter) — multi-stop tour (audio pending)

Image-staged ahead of audio (2026-06-23). **Multi-stop** walk through the Latin
Quarter — "where the city goes to think" — downhill from the Panthéon to the
river. Maker: **Atlas Studio PAR** (🇫🇷 — *create when wiring; shared with the
other Paris tours*). Slug: `paris-leftbank`. **7 tracks** (intro = stop 0).
~2 km, mostly downhill.

When audio lands: build one multi-stop `Tour`, 7 ordered geofenced `Stop`s, each
with `audioURL`, coordinate, `transcriptText` (non-TTS script here), `caption`
(first sentence), `imageURL` below. Set `heroImageURL`, **populate
`additionalImageURLs`** (gallery carousel — #233), `kind=multiStop`,
`walkingDistanceMeters≈2200`, `primaryCategory=history` (the life of the mind),
`city="Paris"`, `totalDurationSeconds`=sum of stop durations. Run validator.

- **Scripts:** `paris_leftbank_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. **All ship-safe
  (Unsplash/Pexels/Pixabay)** — credits in `IMAGE-CREDITS-paris-batch1.txt`.
- **Audio stems:** `paris_leftbank_multistop_NN_<name>_TTS.mp3`.

| Track | Stop | coord (lat, lon) | image |
|---|------|------------------|-------|
| 0 | Intro (Latin Quarter) | 48.8462, 2.3464 | `paris-leftbank_stop0.webp` |
| 1 | Panthéon | 48.8462, 2.3464 | `paris-leftbank_stop1.webp` |
| 2 | Shakespeare and Company | 48.8526, 2.3471 | `paris-leftbank_stop2.webp` |
| 3 | Jardin du Luxembourg | 48.8462, 2.3372 | `paris-leftbank_stop3.webp` |
| 4 | Saint-Sulpice | 48.8511, 2.3349 | `paris-leftbank_stop4.webp` |
| 5 | Saint-Germain-des-Prés | 48.8540, 2.3338 | **reuses `saint-germain-des-pres_hero.webp`** (existing single-stop tour hero, owner's call) |
| 6 | Musée d'Orsay | 48.8600, 2.3266 | `paris-leftbank_stop6.webp` |

**Tour hero:** `paris-leftbank_hero.webp` — Latin Quarter café street (Pexels).

Coords approximate landmark centroids; geofenced (~40 m). Catalog's prospective
**12th multi-stop tour** (after Paris Islands, Triumphal Way, Montmartre, Marais).

**Blocked on:** (1) the 7 narration MP3s; (2) the **Atlas Studio PAR** maker.
