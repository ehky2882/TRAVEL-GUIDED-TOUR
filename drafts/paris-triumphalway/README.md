# "The Triumphal Way" (Axe historique) — multi-stop tour (audio pending)

Image-staged ahead of audio (2026-06-23). **Multi-stop** walk along Paris's
**Axe historique** — the dead-straight ~4 km sightline from the Louvre to the
Arc de Triomphe, with a Métro coda to the Grande Arche at La Défense. "Power
drawn as a line." Maker: **Atlas Studio PAR** (🇫🇷 — *create it when wiring;
shared with Paris Islands + the 45 single-stop Paris tours*). Slug:
`paris-triumphalway`. **7 tracks** (intro = stop 0).

When audio lands: build one multi-stop `Tour`, 7 ordered geofenced `Stop`s, each
with `audioURL`, coordinate, `transcriptText` (non-TTS script here), `caption`
(first sentence), `imageURL` below. Set `heroImageURL`, **populate
`additionalImageURLs`** (gallery carousel reads it — see #233), `kind=multiStop`,
`walkingDistanceMeters≈4000`, `primaryCategory=history`, `city="Paris"`,
`totalDurationSeconds`=sum of stop durations. Run the validator.

- **Scripts:** `paris_triumphalway_multistop_NN_<name>.txt` (display) + `..._TTS.txt`.
- **Images on `gh-pages`** (1200×900 webp), base
  `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`. **All ship-safe
  (Unsplash/Pexels) — no attribution.** Logged in `IMAGE-CREDITS-paris-batch1.txt`.
- **Audio stems:** `paris_triumphalway_multistop_NN_<name>_TTS.mp3`.

| Track | Stop | coord (lat, lon) | image |
|---|------|------------------|-------|
| 0 | Intro (the axis) | 48.8611, 2.3358 | `paris-triumphalway_stop0.webp` |
| 1 | Louvre (glass pyramid) | 48.8611, 2.3364 | `paris-triumphalway_stop1.webp` |
| 2 | Tuileries | 48.8634, 2.3275 | `paris-triumphalway_stop2.webp` |
| 3 | Place de la Concorde | 48.8656, 2.3212 | `paris-triumphalway_stop3.webp` |
| 4 | Champs-Élysées | 48.8698, 2.3079 | `paris-triumphalway_stop4.webp` |
| 5 | Arc de Triomphe | 48.8738, 2.2950 | `paris-triumphalway_stop5.webp` |
| 6 | Grande Arche, La Défense | 48.8926, 2.2361 | `paris-triumphalway_stop6.webp` |

**Tour hero:** `paris-triumphalway_hero.webp` — aerial straight down the axis (Pexels).

Coords are approximate landmark centroids; geofenced (~40 m). Note stop 6 (La
Défense) is ~6 km west of stop 5 — the script frames it as a Métro coda, not a
walk; geofence still fine. Catalog's prospective **9th multi-stop tour** (after
Paris Islands).

**Blocked on:** (1) the 7 narration MP3s; (2) the **Atlas Studio PAR** maker.
