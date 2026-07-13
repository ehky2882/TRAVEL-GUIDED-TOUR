# Montreal — "Plateau & Mile End" multi-stop walk (audio pending) 🇨🇦

Montreal's **third multi-stop walk** — "a way of living, conducted in public": staircases,
balconies, squares, laneways, ending in the Mile End bagel line-up. Intro + 4 stops, ~3 km
flat, a warm-evening walk. Maker **Atlas Studio YUL**. **All stops reuse live batch-3
single-stop heroes — zero new image sourcing.**

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual); stops 1-4 geofenced (radius 40).
- `totalDurationSeconds` = Σ stop durations (from MP3s at wire-in).
- centroid = avg of the 4 stop coords; `walkingDistanceMeters` ≈ **3000** ("about three kilometres end to end").
- Suggested category: `culturalHeritage`.

## Stops (order + coords + reused image)
| # | Stop | reused single-stop image (live) | coord (lat, lon) | trigger |
|---|------|--------------------------------|------------------|---------|
| 0 | Intro — Plateau & Mile End | — (narration only) | 45.51650, -73.56650 (Square Saint-Louis) | manual |
| 1 | Square Saint-Louis | `square-saint-louis_hero.webp` | 45.51650, -73.56650 | geofenced |
| 2 | Plateau streets (staircases) | `plateau-staircases_hero.webp` | 45.51800, -73.57300 (Laval & Duluth) | geofenced |
| 3 | The Main (Boulevard Saint-Laurent) | `the-main-saint-laurent_hero.webp` | 45.51550, -73.57200 | geofenced |
| 4 | Mile End | `mile-end_hero.webp` | 45.52300, -73.60100 | geofenced |

## Images
- **Walk hero:** `square-saint-louis_hero.webp` (the opening, "most photographed houses"). Swap on request.
- **Per-stop `additionalImageURLs`** = the 4 stop heroes above, all live on gh-pages. **No re-upload, no new credits** (batch-3 CC credits for these singles are already logged; the walk adds none).

## Narrative callbacks
The "private life in public" thread runs Square Saint-Louis (formal) → Plateau outdoor
staircases → the Main (the multicultural seam) → Mile End (the bagel line-up). Sibling of the
batch-3 singles it stitches together.

## Wire-in checklist (at audio arrival — 5 MP3s: intro + 4 stops)
1. Create **Atlas Studio YUL** maker.
2. Add one `multiStop` tour: 4 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 3000.
4. `additionalImageURLs` = the 4 stop hero URLs; `heroImageURL` = square-saint-louis hero.
5. `transcriptText` verbatim from each `NN_*.txt` (drop `[beat]`). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 4 stops = 5 files); (2) the Atlas Studio YUL maker.
