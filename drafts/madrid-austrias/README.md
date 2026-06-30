# "Madrid de los Austrias" — Madrid's FIRST multi-stop walk (audio pending)

Image-staged 2026-06-29. A tight westward loop through Habsburg old-town Madrid.
Maker: **Atlas Studio MAD** (🇪🇸 — create in `Tours.json` at first Madrid wire-in;
shared by all Madrid tours). Slug: `madrid-austrias`. **6 tracks** (intro = stop 0).
Flat, ~1.1 km.

When audio lands: one multi-stop `Tour`, **6 ordered geofenced `Stop`s**, each with
`audioURL`, coord, `transcriptText` (non-TTS script here), `caption` (first
sentence), `imageURL` below. Set `heroImageURL`, populate `additionalImageURLs`
(gallery = the 6 stop images), `kind=multiStop`, `introAudioURL=null`,
`walkingDistanceMeters≈1100`, `primaryCategory=history`, `city="Madrid"`,
centroid = avg of stop coords, totalDurationSeconds = sum. Run validator.

- **Scripts:** `madrid_austrias_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Audio stems:** owner records `madrid_austrias_multistop_NN_<name>_TTS.mp3` →
  host on gh-pages as `audio/madrid-austrias_stop{N}.mp3`.
- **Images on `gh-pages`**, base `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.

| Track | Stop | coord (lat, lon) | image (reuses existing single-stop hero) |
|---|------|------------------|------------------------------------------|
| 0 | Intro (Madrid de los Austrias) | 40.4168, -3.7038 | `madrid-austrias_hero.webp` (tour hero, NEW — Z2, ship-safe) |
| 1 | Puerta del Sol (Km 0) | 40.4169, -3.7035 | **reuses `puerta-del-sol_hero.webp`** |
| 2 | Plaza Mayor | 40.4155, -3.7074 | **reuses `plaza-mayor-madrid_hero.webp`** |
| 3 | Mercado de San Miguel | 40.4154, -3.7090 | **reuses `mercado-de-san-miguel_hero.webp`** |
| 4 | Plaza de la Villa | 40.4156, -3.7106 | **reuses `plaza-de-la-villa_hero.webp`** |
| 5 | Palacio Real & the Almudena (Plaza de la Armería) | 40.4180, -3.7144 | **reuses `palacio-real_hero.webp`** |

**Tour hero:** `madrid-austrias_hero.webp` — wide old-town establishing shot
(owner-picked Z2, ship-safe).

Coords approximate; geofence ~40 m. **Only the tour hero is a new image** — every
stop reuses a single-stop Madrid hero already on gh-pages (all the corresponding
single-stop tours are staged: `puerta-del-sol`, `plaza-mayor-madrid`,
`mercado-de-san-miguel`, `plaza-de-la-villa`, `palacio-real`).

NOTE: stop 0 (intro) sits ~at Puerta del Sol, very close to stop 1 — the app's
geofence "already-inside" handling (ProximityMonitor) covers the user starting
inside stop 1's region, so this is fine.

**Blocked on:** (1) the 6 narration MP3s; (2) the **Atlas Studio MAD** maker.
