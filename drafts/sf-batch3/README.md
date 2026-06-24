# San Francisco — single-stop tours, batch 3 (audio pending)

Image-staged 2026-06-24. Continues the SF city build (see `sf-batch1`, `sf-batch2`).
All **single-stop**, geofenced, maker **Atlas Studio SFO** (🇺🇸 — create when
wiring; shared across all SF tours). More SF tours still coming.

When audio lands: single-stop `Tour` each (`kind=single`, 1 stop), hero +
`additionalImageURLs`, caption=first sentence, transcriptText=non-TTS script,
`city="San Francisco"`. Run validator. Audio `sf_NN_<name>_TTS.mp3` → gh-pages
`audio/<slug>.mp3`.

| # | Tour | slug | coord (lat, lon) | suggested category | hero | gallery | notes |
|---|------|------|------------------|--------------------|------|---------|-------|
| 26 | Painted Ladies (Alamo Square) | `painted-ladies` | 37.7762, -122.4329 | architecture | PL1 (row + skyline) | 1 (_2) | ship-safe |
| 28 | Mission Dolores | `mission-dolores` | 37.7644, -122.4269 | sacredSites | owner-supplied (adobe + basilica) | 1 (_2 = PD adobe) | hero owner-supplied; _2 Public Domain |
| 33 | Haight-Ashbury | `haight-ashbury` | 37.7700, -122.4469 | culturalHeritage | HA1 (the street signs) | 3 (_2.._4) | ship-safe |
| 35 | Twin Peaks | `twin-peaks` | 37.7544, -122.4477 | natureAndParks | TP1 (sunset road + city) | 3 (_2.._4) | ship-safe |

Coords approximate; geofence ~40 m. **All ship-safe except Mission Dolores `_2`
(Public Domain — no attribution needed anyway).** Mission Dolores searches
returned the basilica/Dolores Park; the genuine old adobe came from the Wikimedia
Commons category + the owner-supplied hero (which shows adobe + basilica together).

**Blocked on:** (1) narration MP3s; (2) the **Atlas Studio SFO** maker.
