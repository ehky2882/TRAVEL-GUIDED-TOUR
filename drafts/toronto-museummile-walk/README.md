# Toronto — "Museum Mile" multi-stop walk (audio pending) 🇨🇦

Image-staged 2026-06-30. Toronto's **third multi-stop walk** (after Old Town + Downtown
Spine). The "knowledge" walk — the museum + university cluster around Queen's Park,
running roughly N→S. Through-line: institutions that remade themselves — bookended by
**rupture** (the ROM Crystal) and **homecoming** (Gehry's AGO). Maker **Atlas Studio
YYZ** (create at first Toronto wire-in).

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual); stops 1-5 geofenced (radius 40).
- `totalDurationSeconds` = sum of stop durations (from MP3s at wire-in).
- centroid = avg of the 5 stop coords; `walkingDistanceMeters` ≈ **2200** (Bloor down through campus to Dundas; "gentlest walk of the set," flat + shaded).
- Suggested category: `culturalHeritage` (museums + university + legislature) — `visualArt`/`architecture` also defensible.

## Stops (order + coords + image)
| # | Stop | slug (existing images) | coord (lat, lon) | trigger |
|---|------|------------------------|------------------|---------|
| 0 | Intro — Museum Mile | — (narration only) | 43.6677, -79.3948 (ROM, at Bloor/Avenue) | manual |
| 1 | Royal Ontario Museum (the Crystal) | `royal-ontario-museum` | 43.6677, -79.3948 | geofenced |
| 2 | Bata Shoe Museum | `bata-shoe-museum` (**new — BT25**) | 43.6674, -79.4003 | geofenced |
| 3 | University of Toronto / King's College Circle | `uoft-kings-college-circle` | 43.6629, -79.3957 | geofenced |
| 4 | Queen's Park (Ontario Legislature) | `queens-park` | 43.6606, -79.3925 | geofenced |
| 5 | Art Gallery of Ontario | `art-gallery-of-ontario` | 43.6536, -79.3925 | geofenced |

## Images (owner picks 2026-06-30; swap on request)
- **Walk hero:** `royal-ontario-museum_hero.webp` (the Crystal — the intro opens "Look up at the Crystal"). Ship-safe.
- **Per-stop `additionalImageURLs`** — 4 of 5 reuse existing single-stop heroes (no re-upload); only Bata was newly sourced:
  - stop 1 → `royal-ontario-museum_hero.webp` (RM6, ship-safe Pexels)
  - stop 2 → `bata-shoe-museum_hero.webp` (**NEW — BT25, Wikimedia, CC BY 4.0 → see credits**)
  - stop 3 → `uoft-kings-college-circle_hero.webp` (UT4, ship-safe Pexels)
  - stop 4 → `queens-park_hero.webp` (QP1, ship-safe Unsplash)
  - stop 5 → `art-gallery-of-ontario_hero.webp` (owner-supplied Dundas facade)

## Image credits (this walk = ONE new credit)
- `bata-shoe-museum_hero.webp` — "Bata Museum WCNA 2023 (12)" by Jim.henderson, **CC BY 4.0** — https://commons.wikimedia.org/wiki/File:Bata_Museum_WCNA_2023_(12).jpg
- (The Bata "shoebox" building had no ship-safe/CC0 stock — owner OK'd BT25 for this stop. Every other stop image is ship-safe or owner-supplied — no other credit.)

## Narrative callbacks
"Rupture → homecoming" is the spine (ROM Crystal at the start, Gehry's AGO — the local
boy who came home to rebuild the gallery he loved as a child — at the end). E.J. Lennox
reappears at Queen's Park (rebuilt its west wing after the 1909 fire) — the same architect
threaded through Old City Hall, Casa Loma, and the Downtown Spine walk. U of T's stop notes
it "ran the ROM in its early years," tying the campus to stop 1.

## Wire-in checklist (at audio arrival)
1. Create **Atlas Studio YYZ** maker (shared with all staged Toronto content).
2. Add one `multiStop` tour to `Tours.json`: 5 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 2200.
4. `additionalImageURLs` = the 5 stop hero URLs above; `heroImageURL` = ROM Crystal hero.
5. `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 5 stops = 6 files); (2) the Atlas Studio YYZ maker.
