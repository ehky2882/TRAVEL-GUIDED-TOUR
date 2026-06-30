# "El Retiro" — Madrid multi-stop walk (audio pending)

Image-staged 2026-06-29. "The garden handed to everyone" — a walk through the Parque
del Retiro, from a king's gate to a public book market. Maker: **Atlas Studio MAD**
(🇪🇸 — create at first Madrid wire-in; shared by all Madrid tours). Slug:
`madrid-retiro`. **6 tracks** (intro = stop 0). Easy, flat park paths, ~1.8 km.

When audio lands: one multi-stop `Tour`, **6 ordered geofenced `Stop`s**, each with
`audioURL`, coord, `transcriptText` (non-TTS script here), `caption` (first
sentence), `imageURL` below. Set `heroImageURL`, populate `additionalImageURLs`
(gallery = the 6 stop images), `kind=multiStop`, `introAudioURL=null`,
`walkingDistanceMeters≈1800`, `primaryCategory=natureAndParks`, `city="Madrid"`,
centroid = avg of stop coords, totalDurationSeconds = sum. Run validator.

- **Scripts:** `madrid_retiro_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Audio stems:** owner records `..._NN_<name>_TTS.mp3` → gh-pages
  `audio/madrid-retiro_stop{N}.mp3`.
- **Images on `gh-pages`**, base `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.

| Track | Stop | coord (lat, lon) | image |
|---|------|------------------|-------|
| 0 | Intro (the Buen Retiro) | 40.4199, -3.6887 | `madrid-retiro_hero.webp` (tour hero, NEW — Y2, ship-safe) |
| 1 | Puerta de Alcalá | 40.4200, -3.6885 | **reuses `puerta-de-alcala_hero.webp`** |
| 2 | The Estanque & Alfonso XII | 40.4180, -3.6826 | **reuses `parque-del-retiro_hero.webp`** (its hero is the Estanque) |
| 3 | Palacio de Cristal | 40.4137, -3.6824 | **reuses `palacio-de-cristal_hero.webp`** |
| 4 | La Rosaleda (rose garden) | 40.4090, -3.6839 | `madrid-retiro_stop4.webp` (owner-supplied) |
| 5 | Cuesta de Moyano (book stalls) | 40.4099, -3.6907 | `madrid-retiro_stop5.webp` (owner-supplied) |

**Tour hero:** `madrid-retiro_hero.webp` — wide Retiro park shot (owner-picked Y2,
ship-safe). Stops 1–3 reuse existing single-stop Madrid heroes; stops 4 & 5 are
owner-supplied (La Rosaleda + the Cuesta de Moyano book stalls — both too niche for
stock/Wikimedia). All ship-safe or owner-supplied — no attribution this walk.

Coords approximate; geofence ~40 m.

**Blocked on:** (1) the 6 narration MP3s; (2) the **Atlas Studio MAD** maker.
