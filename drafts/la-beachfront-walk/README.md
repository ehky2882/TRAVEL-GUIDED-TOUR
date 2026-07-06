# Los Angeles — Beachfront (Santa Monica → Venice) multi-stop walk (audio pending) 🌴

Image-staged 2026-07-06. Third LA **multi-stop** walk. Maker **Atlas Studio LAX** (shared with LA singles).
`kind multiStop`. Intro stop = manual trigger; all landmark stops geofenced (radius 40).
Theme: "almost nothing on it is doing what it was built to do" — the pier (built for a sewer pipe), Muscle Beach (WPA make-work), Venice (a cultural resort), Abbot Kinney (once repair shops).
Route: ~3 mi south along the beachfront path, Santa Monica Pier → original Muscle Beach → Venice Boardwalk → Venice Canals → Abbot Kinney Blvd.

**Walk slug:** `beachfront-walk` · **hero:** `beachfront-walk_hero.webp` (BF30, Santa Monica Pier + coastline aerial — Pexels, **ship-safe**), pushed 2026-07-06 (`e6c2e97`).

## Stops — every landmark REUSES an existing single-tour hero (no new stop images)
| # | Stop | trigger | coord (lat, lon) approx | stop imageURL (reused) |
|---|------|---------|-------------------------|------------------------|
| 0 | Intro — Santa Monica Pier | manual | 34.0094, -118.4973 | (none) |
| 1 | Santa Monica Pier | geofenced | 34.0094, -118.4973 | `santa-monica-pier_hero.webp` |
| 2 | Muscle Beach (original, Santa Monica) | geofenced | 34.0086, -118.4977 | `muscle-beach_hero.webp` |
| 3 | Venice Beach Boardwalk | geofenced | 33.9850, -118.4695 | `venice-boardwalk_hero.webp` |
| 4 | Venice Canals | geofenced | 33.9825, -118.4660 | `venice-canals_hero.webp` |
| 5 | Abbot Kinney Boulevard | geofenced | 33.9910, -118.4670 | `abbot-kinney_hero.webp` |

Coords are approximate — refine at wire-in against the scripts' "start at…/turn south…" cues.

## Walk gallery (`additionalImageURLs`) — suggestion, set at wire-in
Reuse the stop heroes to preview the route: `santa-monica-pier_hero`, `muscle-beach_hero`,
`venice-boardwalk_hero`, `venice-canals_hero`, `abbot-kinney_hero`.

## Image credits (walk)
- **Walk hero BF30 = ship-safe (Pexels).**
- **All 5 reused stop heroes are ship-safe / owner** (Santa Monica Pier, Muscle Beach, Venice Boardwalk, Venice Canals, Abbot Kinney — none carry a credit per their single-tour entries). **No new attribution obligations from this walk.** (Overlaps entirely with the Downtown/Museum-Row reuse pattern.)

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Walk = `kind multiStop`; stop 0 intro `triggerMode manual` (no image); stops 1–5 `geofenced` radius 40.
3. `totalDurationSeconds` = sum of stop MP3 durations; `walkingDistanceMeters` ≈ 4800 (~3 mi).
4. Stop `imageURL`s = the reused webps above; walk `heroImageURL` = `beachfront-walk_hero.webp`.
5. Durations from the MP3s (mutagen). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) 6 narration MP3s (intro + 5 stops); (2) Atlas Studio LAX maker. (Images complete.)
