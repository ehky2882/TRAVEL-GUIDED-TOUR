# Los Angeles — Downtown multi-stop walk (audio pending) 🌴

Image-staged 2026-07-06. First LA **multi-stop** walk. Maker **Atlas Studio LAX** (shared with LA singles).
`kind multiStop`. Intro stop = manual trigger; all landmark stops geofenced (radius 40).
Theme: "the clock runs backward" — Bunker Hill (2003) descending to the founding plaza (1781), ~1.5 mi.

**Walk slug:** `downtown-la-walk` · **hero:** `downtown-la-walk_hero.webp` (D25, Bunker Hill aerial — Disney Hall + Music Center + tower cluster; Pexels, **ship-safe**), pushed 2026-07-06 (`058f2f6`).

## Stops — every landmark REUSES an existing single-tour hero (no new stop images)
| # | Stop | trigger | coord (lat, lon) approx | stop imageURL (reused) |
|---|------|---------|-------------------------|------------------------|
| 0 | Intro — First St & Grand Ave | manual | 34.0553, -118.2498 | (none) |
| 1 | Walt Disney Concert Hall (2003) | geofenced | 34.0553, -118.2498 | `walt-disney-concert-hall_hero.webp` |
| 2 | The Broad (2015) | geofenced | 34.0546, -118.2507 | `the-broad_hero.webp` |
| 3 | MOCA Grand Avenue (1986) | geofenced | 34.0536, -118.2515 | `moca-grand-avenue_hero.webp` |
| 4 | Angels Flight (1901) | geofenced | 34.0513, -118.2500 | `angels-flight_hero.webp` |
| 5 | Grand Central Market (1917) | geofenced | 34.0506, -118.2489 | `grand-central-market_hero.webp` |
| 6 | Bradbury Building (1893) | geofenced | 34.0505, -118.2477 | `bradbury-building_hero.webp` |
| 7 | El Pueblo / Olvera Street (1781) | geofenced | 34.0577, -118.2385 | `el-pueblo-olvera-street_hero.webp` |

Coords are approximate — refine at wire-in against the scripts' "start at…" cues.

## Walk gallery (`additionalImageURLs`) — suggestion, set at wire-in
Reuse the stop heroes to preview the journey: `walt-disney-concert-hall_hero`, `the-broad_hero`,
`angels-flight_hero`, `bradbury-building_hero`, `el-pueblo-olvera-street_hero`. (Owner may swap in a
second aerial — D8 golden-hour or D7 skyline+mountains were the runners-up.)

## Image credits (walk)
- **Walk hero D25 = ship-safe (Pexels).**
- **Inherited, not new:** stop 3 MOCA hero (M32 = Minnaert, **CC BY-SA 3.0**) is already logged in
  `drafts/CREDITS.md` under the MOCA single (03). All other reused stop heroes are ship-safe / PD /
  owner-supplied (El Pueblo). No new attribution obligations from this walk.

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Walk = `kind multiStop`; stop 0 intro `triggerMode manual` (no image); stops 1–7 `geofenced` radius 40.
3. `totalDurationSeconds` = sum of stop MP3 durations; `walkingDistanceMeters` ≈ 2400 (~1.5 mi).
4. Stop `imageURL`s = the reused webps above; walk `heroImageURL` = `downtown-la-walk_hero.webp`.
5. Durations from the MP3s (mutagen). `swift scripts/validate-tours.swift`.

**Blocked on:** (1) 8 narration MP3s (intro + 7 stops); (2) Atlas Studio LAX maker. (Images complete.)
