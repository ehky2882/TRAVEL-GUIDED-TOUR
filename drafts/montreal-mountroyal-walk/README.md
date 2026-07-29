# Montreal — "Mount Royal" multi-stop walk (audio pending) 🇨🇦

Montreal's **second multi-stop walk** — the climb up the mountain, framed by Maisonneuve's
1643 vow. Intro + 4 stops, a real uphill (~45 min up, ~2 hr round trip). Maker **Atlas Studio
YUL** (created at first Montreal wire-in).

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual trigger); stops 1-4 geofenced (radius 40).
- `totalDurationSeconds` = sum of stop durations (from MP3s at wire-in).
- centroid = avg of the 4 stop coords; `walkingDistanceMeters` ≈ **1800** (Peel entrance → summit/cross, one way; it's a climb).
- Suggested category: `natureAndParks` (`history` also defensible — the Maisonneuve through-line).

## Stops (order + coords + image)
| # | Stop | image (live on gh-pages) | coord (lat, lon) | trigger |
|---|------|--------------------------|------------------|---------|
| 0 | Intro — the climb | — (narration only) | 45.49900, -73.58300 (Peel & des Pins) | manual |
| 1 | Peel entrance | `mount-royal-trail_hero.webp` (forest path; owner default MXS13 — swap on request) | 45.49900, -73.58300 | geofenced |
| 2 | Olmsted climb / switchbacks | `mount-royal-trail_2.webp` (staircase, MXS1) | 45.50150, -73.58550 | geofenced |
| 3 | Kondiaronk Belvedere | `mount-royal-belvedere_hero.webp` (**reuses the live single-stop hero**) | 45.50440, -73.58750 | geofenced |
| 4 | The Cross | `mount-royal-cross_hero.webp` (MXC8) | 45.50820, -73.58760 | geofenced |

## Images (all live on gh-pages)
- **Walk hero:** `mount-royal-belvedere_hero.webp` (the summit view — the payoff). Alternative: the Cross (`mount-royal-cross_hero.webp`) for the narrative climax — owner to confirm.
- **New images sourced for this walk (3):** trail entrance (MXS13), climb staircase (MXS1), the Cross (MXC8). Belvedere stop reuses the live single-stop hero.

## Image credits (this walk = 2 CC-credited; the Cross is ship-safe)
- `mount-royal-trail_hero.webp` (entrance) — Matias Garabedian — **CC BY-SA 2.0** — https://commons.wikimedia.org/wiki/File:Au_bonheur_de_l%27automne_au_parc_Mont-Royal_(15341849438).jpg
- `mount-royal-trail_2.webp` (climb) — Yanik Crépeau — **CC BY-SA 3.0** — https://commons.wikimedia.org/wiki/File:Golden_Square_Mile,_Montreal,_QC,_Canada_-_panoramio_(14).jpg
- `mount-royal-cross_hero.webp` (the Cross) — **Unsplash, ship-safe, no credit**. Belvedere hero = ship-safe (see batch-3 singles).

## Narrative callbacks
Bookended by Maisonneuve's 1643 vow (carrying a cross up the mountain) — ties back to the
Place d'Armes monument (Old Montreal walk stop 1) and Notre-Dame. Olmsted (Central Park)
designed the deliberately slow switchbacks; the summit belvedere is also a single-stop tour.

## Wire-in checklist (at audio arrival — 5 MP3s: intro + 4 stops)
1. Create **Atlas Studio YUL** maker (shared with all staged Montreal content).
2. Add one `multiStop` tour: 4 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 1800.
4. `additionalImageURLs` = the 4 stop images above; `heroImageURL` = belvedere hero (or Cross).
5. `transcriptText` verbatim from each `NN_*.txt` (drop `[beat]`). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 4 stops = 5 files); (2) the Atlas Studio YUL maker.
