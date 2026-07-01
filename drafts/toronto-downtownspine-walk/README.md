# Toronto — "Downtown Spine" multi-stop walk (audio pending) 🇨🇦

Image-staged 2026-06-30. Toronto's **second multi-stop walk** (after Old Town). The
"money-and-power" line running north from the lake — CN Tower → the banks and the
hidden city beneath them → the two city halls staring each other down across Bay St.
Through-line: "a city that would rather repurpose a building than lose it." Maker
**Atlas Studio YYZ** (create at first Toronto wire-in).

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual trigger); stops 1-5 geofenced (radius 40).
- `totalDurationSeconds` = sum of stop durations (from MP3s at wire-in).
- centroid = avg of the 5 stop coords; `walkingDistanceMeters` ≈ **1500** (straight line N, ~20min not counting stops).
- Suggested category: `architecture` (CN Tower, Mies TD Centre, Brookfield canopy, both city halls) — `history` also defensible.

## Stops (order + coords + image)
| # | Stop | slug (existing images) | coord (lat, lon) | trigger |
|---|------|------------------------|------------------|---------|
| 0 | Intro — Downtown Spine | — (narration only) | 43.6426, -79.3871 (CN Tower base) | manual |
| 1 | CN Tower | `cn-tower` | 43.6426, -79.3871 | geofenced |
| 2 | Hockey Hall of Fame (Brookfield Place) | `hockey-hall-of-fame` | 43.6472, -79.3777 | geofenced |
| 3 | Financial District / TD Centre / PATH | `financial-district` | 43.6484, -79.3806 | geofenced |
| 4 | Nathan Phillips Square (New City Hall) | `nathan-phillips-square` | 43.6525, -79.3838 | geofenced |
| 5 | Old City Hall | `old-city-hall` | 43.6525, -79.3817 | geofenced |

## Images — ALL REUSED (owner default 2026-06-30; swap on request)
- **Walk hero:** `cn-tower_hero.webp` (the intro opens "look up at the CN Tower / where the whole skyline starts").
- **Per-stop `additionalImageURLs`** reuse the existing single-stop heroes already live on gh-pages — **no new images sourced, no re-upload:**
  - stop 1 → `cn-tower_hero.webp`
  - stop 2 → `hockey-hall-of-fame_hero.webp`
  - stop 3 → `financial-district_hero.webp`
  - stop 4 → `nathan-phillips-square_hero.webp`
  - stop 5 → `old-city-hall_hero.webp`
- **Credits:** NONE required for this walk. The stop-2 image used here is `hockey-hall-of-fame_hero.webp` (HH6, ship-safe building exterior) — NOT the two CC BY-SA interior gallery shots (`hockey-hall-of-fame_2/_4`, Christopher Amrich) which are only in the single-stop tour's gallery, not this walk. Every other stop hero is ship-safe/owner.
- **Optional enhancement (not done):** stop 2's script is really about Brookfield Place's white ribcage canopy + the old Bank of Montreal banking hall (now holding the Stanley Cup). The reused `hockey-hall-of-fame_hero` is a building exterior; a Brookfield-canopy or gilded-banking-hall shot would fit the narration better if the owner wants to source/paste one later.

## Narrative callbacks
Self-referential like Old Town: the "repurpose don't demolish" thread (bank→hockey shrine,
Old City Hall saved from demolition) ties every stop; the closing two-city-halls standoff
is the payoff. Old City Hall shares architect E.J. Lennox with Casa Loma + the Queen's Park
wing (other Toronto tours); its script even nods to St. Lawrence Market North (the Old Town
walk's stop 4) taking in the relocated courts.

## Wire-in checklist (at audio arrival)
1. Create **Atlas Studio YYZ** maker (shared with all staged Toronto content).
2. Add one `multiStop` tour to `Tours.json`: 5 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 1500.
4. `additionalImageURLs` = the 5 stop hero URLs above; `heroImageURL` = cn-tower hero (or swap).
5. `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 5 stops = 6 files); (2) the Atlas Studio YYZ maker.
