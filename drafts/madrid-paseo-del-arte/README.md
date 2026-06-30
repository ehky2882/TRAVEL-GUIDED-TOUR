# "Paseo del Arte" — Madrid multi-stop walk (audio pending)

Image-staged 2026-06-29. North→south down the Paseo del Prado — the "Landscape of
Light" (UNESCO 2021), the golden triangle of art. Maker: **Atlas Studio MAD** (🇪🇸
— create at first Madrid wire-in; shared by all Madrid tours). Slug:
`madrid-paseo-del-arte`. **7 tracks** (intro = stop 0). Flat, ~1.3 km.

When audio lands: one multi-stop `Tour`, **7 ordered geofenced `Stop`s**, each with
`audioURL`, coord, `transcriptText` (non-TTS script here), `caption` (first
sentence), `imageURL` below. Set `heroImageURL`, populate `additionalImageURLs`
(gallery = the 7 stop images), `kind=multiStop`, `introAudioURL=null`,
`walkingDistanceMeters≈1300`, `primaryCategory=visualArt`, `city="Madrid"`,
centroid = avg of stop coords, totalDurationSeconds = sum. Run validator.

- **Scripts:** `madrid_paseodelarte_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Audio stems:** owner records `..._NN_<name>_TTS.mp3` → gh-pages
  `audio/madrid-paseo-del-arte_stop{N}.mp3`.
- **Images on `gh-pages`**, base `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.

| Track | Stop | coord (lat, lon) | image (reuses existing single-stop hero) |
|---|------|------------------|------------------------------------------|
| 0 | Intro (Paseo del Prado) | 40.4198, -3.6928 | `madrid-paseo-del-arte_hero.webp` (tour hero, NEW — Q2, ship-safe) |
| 1 | Fuente de Cibeles | 40.4193, -3.6932 | **reuses `fuente-de-cibeles_hero.webp`** |
| 2 | Fuente de Neptuno | 40.4154, -3.6939 | **reuses `fuente-de-neptuno_hero.webp`** (CC BY-SA 3.0 — logged in batch 3) |
| 3 | Museo del Prado | 40.4138, -3.6921 | **reuses `museo-del-prado_hero.webp`** |
| 4 | Thyssen-Bornemisza | 40.4160, -3.6948 | **reuses `museo-thyssen-bornemisza_hero.webp`** (owner-supplied) |
| 5 | CaixaForum | 40.4111, -3.6936 | **reuses `caixaforum-madrid_hero.webp`** (CC BY-SA 4.0 — logged in batch 3) |
| 6 | Reina Sofía | 40.4080, -3.6946 | **reuses `museo-reina-sofia_hero.webp`** (owner-supplied) |

**Tour hero:** `madrid-paseo-del-arte_hero.webp` — Paseo del Prado boulevard
(owner-picked Q2, ship-safe).

Coords approximate; geofence ~40 m. **Only the tour hero is a new image** — every
stop reuses a single-stop Madrid hero already on gh-pages (the corresponding
single-stop tours are all staged: `fuente-de-cibeles`, `fuente-de-neptuno`,
`museo-del-prado`, `museo-thyssen-bornemisza`, `caixaforum-madrid`,
`museo-reina-sofia`). License notes for the reused CC BY-SA heroes carry over from
`drafts/madrid-batch3/IMAGE-CREDITS-madrid-batch3.txt`.

NOTE: stop 6 (Reina Sofía) — the script discusses Picasso's *Guernica* but no
interior/artwork image is used (Guernica is copyrighted + photo-banned); the
reused Reina Sofía hero is the owner-supplied exterior, which is correct.

**Blocked on:** (1) the 7 narration MP3s; (2) the **Atlas Studio MAD** maker.
