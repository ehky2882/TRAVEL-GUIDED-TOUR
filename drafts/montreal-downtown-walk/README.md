# Montreal — "Downtown / Underground City" multi-stop walk (audio pending) 🇨🇦

Montreal's **fourth multi-stop walk** — the winter-proof downtown route, ending underground
in the RÉSO beneath a cathedral. Intro + 4 stops, ~1.5 km flat. Maker **Atlas Studio YUL**.
**All stops reuse live batch-2/3 single-stop heroes — zero new image sourcing.**

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual); stops 1-4 geofenced (radius 40).
- `totalDurationSeconds` = Σ stop durations (from MP3s at wire-in).
- centroid = avg of the 4 stop coords; `walkingDistanceMeters` ≈ **1500** ("about a kilometre and a half").
- Suggested category: `culturalHeritage` (`architecture` also fine).

## Stops (order + coords + reused image)
| # | Stop | reused single-stop image (live) | coord (lat, lon) | trigger |
|---|------|--------------------------------|------------------|---------|
| 0 | Intro — Downtown / Underground | — (narration only) | 45.49970, -73.57100 (Dorchester Square) | manual |
| 1 | Dorchester Square & Sun Life | `dorchester-sun-life_hero.webp` | 45.49970, -73.57100 | geofenced |
| 2 | Mary, Queen of the World Cathedral | `mary-queen-cathedral_hero.webp` | 45.49950, -73.56950 | geofenced |
| 3 | Place Ville Marie / RÉSO | `place-ville-marie_hero.webp` | 45.50170, -73.56860 | geofenced |
| 4 | Christ Church Cathedral / Promenades Cathédrale | `christ-church-cathedral_hero.webp` | 45.50390, -73.56950 | geofenced |

## Images
- **Walk hero:** `dorchester-sun-life_hero.webp` (the opening grand landmark). Swap on request (Place Ville Marie or the Cathedral also work).
- **Per-stop `additionalImageURLs`** = the 4 stop heroes above, all live on gh-pages. **No re-upload, no new credits** (christ-church-cathedral is a batch-2 single; the rest batch-3 — their credits already logged).

## Narrative callbacks
The "winter as a design problem" thread ends in the RÉSO under Christ Church (the "floating
church" the batch-2 single describes). Sun Life's wartime gold vault, Mary Queen's "St Peter's
in enemy territory," and Place Ville Marie's "tower that started it all by digging a hole" all
recur from the batch-3 singles this walk stitches together.

## Wire-in checklist (at audio arrival — 5 MP3s: intro + 4 stops)
1. Create **Atlas Studio YUL** maker.
2. Add one `multiStop` tour: 4 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 1500.
4. `additionalImageURLs` = the 4 stop hero URLs; `heroImageURL` = dorchester-sun-life hero.
5. `transcriptText` verbatim from each `NN_*.txt` (drop `[beat]`). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 4 stops = 5 files); (2) the Atlas Studio YUL maker.
