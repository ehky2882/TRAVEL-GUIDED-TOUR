# "Le Marais" — multi-stop tour (audio pending)

Image-staged ahead of audio (2026-06-23). **Multi-stop** walk through the Marais
— the largest surviving piece of old Paris, the marsh that became the address,
the slum, then "the city's living room." Maker: **Atlas Studio PAR** (🇫🇷 —
*create when wiring; shared with the other Paris tours*). Slug: `paris-marais`.
**6 tracks** (intro = stop 0). Flat, dense.

When audio lands: build one multi-stop `Tour`, 6 ordered geofenced `Stop`s, each
with `audioURL`, coordinate, `transcriptText` (non-TTS script here), `caption`
(first sentence), `imageURL` below. Set `heroImageURL`, **populate
`additionalImageURLs`** (gallery carousel — #233), `kind=multiStop`,
`walkingDistanceMeters≈2500`, `primaryCategory=culturalHeritage` (or `history`),
`city="Paris"`, `totalDurationSeconds`=sum of stop durations. Run validator.

- **Scripts:** `paris_marais_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. Credits in
  `IMAGE-CREDITS-paris-batch1.txt`.
- **Audio stems:** `paris_marais_multistop_NN_<name>_TTS.mp3`.

| Track | Stop | coord (lat, lon) | image |
|---|------|------------------|-------|
| 0 | Intro (the Marais) | 48.8580, 2.3600 | `paris-marais_stop0.webp` (Pexels) |
| 1 | Hôtel de Ville | 48.8565, 2.3525 | `paris-marais_stop1.webp` (Pexels) |
| 2 | Centre Pompidou | 48.8607, 2.3522 | `paris-marais_stop2.webp` (Pexels) |
| 3 | Musée Picasso (Hôtel Salé) | 48.8598, 2.3626 | `paris-marais_stop3.webp` (**CC BY-SA 3.0**, LPLT — logged) |
| 4 | Place des Vosges | 48.8554, 2.3655 | `paris-marais_stop4.webp` (Pexels) |
| 5 | Musée Carnavalet | 48.8575, 2.3627 | **reuses `musee-carnavalet_hero.webp`** (existing single-stop tour hero, owner's call) |

**Tour hero:** `paris-marais_hero.webp` — old Marais street (Pexels, ship-safe).

Coords approximate landmark centroids; geofenced (~40 m). Catalog's prospective
**11th multi-stop tour** (after Paris Islands + Triumphal Way + Montmartre).

**Blocked on:** (1) the 6 narration MP3s; (2) the **Atlas Studio PAR** maker.
