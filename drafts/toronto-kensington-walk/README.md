# Toronto — "Immigrant West / Kensington" multi-stop walk (audio pending) 🇨🇦

Image-staged 2026-06-30. Toronto's **fourth multi-stop walk** (after Old Town, Downtown
Spine, Museum Mile). The "immigrant west" — the part of the city that "grew by addition
rather than replacement," layer over layer. Maker **Atlas Studio YYZ** (create at first
Toronto wire-in).

## Tour shape (`kind: multiStop`)
- `introAudioURL: null` — intro IS stop 0 (manual); stops 1-5 geofenced (radius 40).
- `totalDurationSeconds` = sum of stop durations (from MP3s at wire-in).
- centroid = avg of the 5 stop coords; `walkingDistanceMeters` ≈ **2500** (~45min actual walking, "flat, dense," one short leg back south; Queen/Spadina streetcars parallel it).
- Suggested category: `culturalHeritage` (immigrant-heritage neighbourhoods) — `visualArt` also defensible (AGO + Graffiti Alley).

## Stops (order + coords + image)
| # | Stop | slug (existing images) | coord (lat, lon) | trigger |
|---|------|------------------------|------------------|---------|
| 0 | Intro — Immigrant West | — (narration only) | 43.6536, -79.3925 (AGO, Dundas/McCaul) | manual |
| 1 | Art Gallery of Ontario (the Grange) | `art-gallery-of-ontario` | 43.6536, -79.3925 | geofenced |
| 2 | Chinatown (Spadina) | `chinatown-spadina` | 43.6529, -79.3980 | geofenced |
| 3 | Kensington Market | `kensington-market` | 43.6547, -79.4005 | geofenced |
| 4 | Graffiti Alley (Rush Lane) | `graffiti-alley` | 43.6485, -79.3980 | geofenced |
| 5 | Queen Street West | `queen-street-west` | 43.6430, -79.4130 | geofenced |

## Images — ALL REUSED (owner default 2026-06-30; swap on request)
- **Walk hero:** `art-gallery-of-ontario_hero.webp` (owner's Gehry Dundas facade — the intro/stop 1 opens here). Ship-safe/owner.
- **Per-stop `additionalImageURLs`** reuse the existing single-stop heroes — **no new images sourced, no re-upload:**
  - stop 1 → `art-gallery-of-ontario_hero.webp` (owner-supplied)
  - stop 2 → `chinatown-spadina_hero.webp` (CH17, ship-safe Pexels)
  - stop 3 → `kensington-market_hero.webp` (KM24, ship-safe Pexels)
  - stop 4 → `graffiti-alley_hero.webp` (owner-supplied portrait mural)
  - stop 5 → `queen-street-west_hero.webp` (QV42, the Drake Hotel — **CC BY-SA 3.0, see credits**)

## Image credits (this walk = ONE, carried over from the single-stop tour)
- `queen-street-west_hero.webp` (Drake Hotel) — SimonP, **CC BY-SA 3.0** — https://commons.wikimedia.org/wiki/File:Drake_Hotel.jpg
- (Same image already credited in `drafts/toronto-batch7`. Every other stop image here is ship-safe or owner-supplied — no additional credit.)

## Narrative callbacks
Deliberate sibling of Museum Mile: both start at the AGO but pull opposite directions —
Museum Mile treats the AGO as the "homecoming" endpoint (Gehry), while this walk uses it as
the *opening* model of "accretion" (the Grange folded inside the galleries). The "grew by
addition, kept every layer" thread runs Chinatown → Kensington → Graffiti Alley → Queen West,
each a single-stop tour in the catalog already.

## Wire-in checklist (at audio arrival)
1. Create **Atlas Studio YYZ** maker (shared with all staged Toronto content).
2. Add one `multiStop` tour to `Tours.json`: 5 stops in order, geofenced/radius 40; intro = stop 0 manual, `introAudioURL: null`.
3. `totalDurationSeconds` = Σ stop durations (mutagen); centroid = avg stop coords; `walkingDistanceMeters` ≈ 2500.
4. `additionalImageURLs` = the 5 stop hero URLs above; `heroImageURL` = AGO hero.
5. `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s (intro + 5 stops = 6 files); (2) the Atlas Studio YYZ maker.
