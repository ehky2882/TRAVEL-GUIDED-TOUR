# Montreal — "Old Montreal" multi-stop walk (audio pending) 🇨🇦

Montreal's **first multi-stop walk**. Five stops through the founding core, ~1.5 km flat
(cobblestone), narrated as "the city's biography, out of order." Maker **Atlas Studio YUL**
(created at first Montreal wire-in). **All stops reuse live batch-1 single-stop heroes — zero
new image sourcing.**

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual trigger); stops 1-5 geofenced (radius 40).
- `totalDurationSeconds` = sum of stop durations (from MP3s at wire-in).
- centroid = avg of the 5 stop coords; `walkingDistanceMeters` ≈ **1500** ("about a kilometre and a half").
- Suggested category: `history` (`culturalHeritage` also fine).
- **Narrative order is deliberately non-geographic** (intro: "the story won't arrive entirely in order"): start mid-district at Place d'Armes, drop back to the founding ground, then work forward to the water.

## Stops (order + coords + reused image)
| # | Stop | reused single-stop image (live) | coord (lat, lon) | trigger |
|---|------|--------------------------------|------------------|---------|
| 0 | Intro — Old Montreal | — (narration only) | 45.50451, -73.55627 (Place d'Armes) | manual |
| 1 | Place d'Armes | `notre-dame-basilica_hero.webp` | 45.50451, -73.55627 | geofenced |
| 2 | Pointe-à-Callière | `pointe-a-calliere_hero.webp` | 45.50201, -73.55418 | geofenced |
| 3 | Place Jacques-Cartier | `place-jacques-cartier-city-hall_hero.webp` | 45.50789, -73.55283 | geofenced |
| 4 | Bonsecours Market | `bonsecours-market-chapel_hero.webp` | 45.50820, -73.55150 | geofenced |
| 5 | Old Port | `old-port_hero.webp` | 45.50630, -73.54780 | geofenced |

## Images
- **Walk hero:** `notre-dame-basilica_hero.webp` (Place d'Armes / Notre-Dame — the opening stop). Swap on request.
- **Per-stop `additionalImageURLs`** = the 5 stop heroes above, all already live on gh-pages. **No re-upload, no new credits** (the batch-1 CC credits for Place Jacques-Cartier / Pointe-à-Callière / Bonsecours are already in `drafts/CREDITS.md`; the walk adds none).

## Wire-in checklist (at audio arrival — 6 MP3s: intro + 5 stops)
1. Create **Atlas Studio YUL** maker (shared with all staged Montreal content).
2. Add one `multiStop` tour to `Tours.json`: 5 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 1500.
4. `additionalImageURLs` = the 5 stop hero URLs above; `heroImageURL` = notre-dame-basilica hero.
5. `transcriptText` = verbatim from each `NN_*.txt` (drop the literal `[beat]` line). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 5 stops = 6 files); (2) the Atlas Studio YUL maker (created at first Montreal wire-in, singles or walk).
