# "The Mission" — SF multi-stop walk (audio pending) — 3rd SF multi-stop

Image-staged 2026-06-24. Walk through the Mission — where San Francisco began
(1776) and where it's still beginning. Oldest building to youngest art. Maker:
**Atlas Studio SFO** (🇺🇸 — create when wiring; shared with all SF tours). Slug:
`sf-mission`. **5 tracks** (intro = stop 0). Flat, ~1 mi.

When audio lands: one multi-stop `Tour`, 5 ordered geofenced `Stop`s, each with
`audioURL`, coord, `transcriptText` (non-TTS script here), `caption` (first
sentence), `imageURL` below. Set `heroImageURL`, **populate `additionalImageURLs`**
(gallery — #233), `kind=multiStop`, `walkingDistanceMeters≈1700`,
`primaryCategory=culturalHeritage`, `city="San Francisco"`. Validator.

- **Scripts:** `sf_mission_multistop_NN_<name>.txt` + `..._TTS.txt`.
- **Audio stems:** `sf_mission_multistop_NN_<name>_TTS.mp3` → gh-pages
  `audio/sf-mission_stop{N}.mp3`.

| Track | Stop | coord (lat, lon) | image |
|---|------|------------------|-------|
| 0 | Intro (the Mission) | 37.7610, -122.4210 | `sf-mission_stop0.webp` (Mission street, ship-safe) |
| 1 | Mission Dolores | 37.7644, -122.4269 | **reuses `mission-dolores_hero.webp`** |
| 2 | Dolores Park | 37.7596, -122.4269 | **reuses `dolores-park_hero.webp`** |
| 3 | Clarion Alley | 37.7625, -122.4197 | **reuses `balmy-clarion-alleys_hero.webp`** |
| 4 | Balmy Alley / 24th Street | 37.7510, -122.4124 | **reuses `balmy-clarion-alleys_2.webp`** |

**Tour hero:** `sf-mission_hero.webp` — Mission street + shops (ship-safe).

Coords approximate; geofence ~40 m. Only the hero + stop0 are new (ship-safe);
all 4 stops reuse existing SF single-stop images (same landmarks/alleys).

**Blocked on:** (1) the 5 narration MP3s; (2) the **Atlas Studio SFO** maker.
