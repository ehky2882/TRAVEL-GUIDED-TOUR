# Los Angeles — Museum Row / Miracle Mile multi-stop walk (audio pending) 🌴

Image-staged 2026-07-06. Second LA **multi-stop** walk. Maker **Atlas Studio LAX** (shared with LA singles).
`kind multiStop`. Intro stop = manual trigger; all landmark stops geofenced (radius 40).
Theme: "everything here came up out of the ground" — the tar pits, the oil fortunes, the boulevard itself.
Route: La Brea Tar Pits → LACMA → Academy Museum → Petersen → Original Farmers Market, ~1.5 mi west along Wilshire then north up Fairfax.

**Walk slug:** `museum-row-walk` · **hero:** `museum-row-walk_hero.webp` (M32, LACMA **Urban Light** at dusk — Pexels, **ship-safe**), pushed 2026-07-06 (`64ca6a5`).

## Stops — every landmark REUSES an existing single-tour hero (no new stop images)
| # | Stop | trigger | coord (lat, lon) approx | stop imageURL (reused) |
|---|------|---------|-------------------------|------------------------|
| 0 | Intro — La Brea Tar Pits, Wilshire & Curson | manual | 34.0636, -118.3560 | (none) |
| 1 | La Brea Tar Pits (Lake Pit) | geofenced | 34.0636, -118.3560 | `la-brea-tar-pits_hero.webp` |
| 2 | LACMA (Geffen Galleries) | geofenced | 34.0639, -118.3592 | `lacma-geffen-galleries_hero.webp` |
| 3 | Academy Museum of Motion Pictures | geofenced | 34.0637, -118.3592 | `academy-museum_hero.webp` |
| 4 | Petersen Automotive Museum | geofenced | 34.0619, -118.3614 | `petersen-automotive_hero.webp` |
| 5 | Original Farmers Market | geofenced | 34.0722, -118.3576 | `farmers-market-grove_hero.webp` |

Coords are approximate — refine at wire-in against the scripts' "start at…/find the…" cues.

## Walk gallery (`additionalImageURLs`) — suggestion, set at wire-in
Reuse the stop heroes to preview the route: `la-brea-tar-pits_hero`, `lacma-geffen-galleries_hero`,
`academy-museum_hero`, `petersen-automotive_hero`, `farmers-market-grove_hero`.

## Image credits (walk)
- **Walk hero M32 = ship-safe (Pexels).**
- **Inherited, not new** (all already in `drafts/CREDITS.md` under their singles):
  - La Brea Tar Pits hero (W8) — Downtowngal, CC BY-SA 4.0
  - Farmers Market stop hero = `farmers-market-grove_hero` (F1, Unsplash) — ship-safe
  - LACMA/Academy/Petersen stop heroes = owner-pasted / ship-safe (per their single-tour credits)
- No NEW attribution obligations from this walk.

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Walk = `kind multiStop`; stop 0 intro `triggerMode manual` (no image); stops 1–5 `geofenced` radius 40.
3. `totalDurationSeconds` = sum of stop MP3 durations; `walkingDistanceMeters` ≈ 2400 (~1.5 mi).
4. Stop `imageURL`s = the reused webps above; walk `heroImageURL` = `museum-row-walk_hero.webp`.
5. Durations from the MP3s (mutagen). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) 6 narration MP3s (intro + 5 stops); (2) Atlas Studio LAX maker. (Images complete.)
