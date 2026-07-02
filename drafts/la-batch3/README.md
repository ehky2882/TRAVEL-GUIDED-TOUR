# Los Angeles — tours, batch 3 (audio pending) 🌴

Image-staged 2026-07-02. Third LA batch — downtown / Bunker Hill core.
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–2).
Tour numbers are the owner's scheme (fills gaps 03/05/06/07).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 03 | MOCA Grand Avenue | `moca-grand-avenue` | 34.0556, -118.2500 | visualArt | M32 (red-sandstone entrance, CC BY-SA) | 2 (_2 M28 sculpture, _3 M31 plaza — both CC) |
| 05 | Angels Flight | `angels-flight` | 34.0511, -118.2497 | culturalHeritage | A15 (car at station) | 4 (_2 A1, _3 A11, _4 A12, _5 A13) |
| 06 | Bradbury Building | `bradbury-building` | 34.0505, -118.2479 | architecture | B1 (atrium lobby) | 7 (_2 B7 elevators, _3 B9, _4 B10, _5 B6, _6 B8, _7 B2 stair, _8 B4 exterior) |
| 07 | LA City Hall | `la-city-hall` | 34.0537, -118.2427 | architecture | C19 (tower at dusk) | 4 (_2 C20, _3 C23, _4 C4, _5 C22) |

## Status (2026-07-02) — all 4 image-staged + pushed to gh-pages (`103c448`)
- **05 Angels Flight / 06 Bradbury / 07 City Hall:** deep, clean ship-safe stock (Unsplash/Pexels) — no credit. Bradbury hero is the **interior atrium** (the script notes the exterior is deliberately plain; B4 exterior kept as last gallery). City Hall filtered out Beverly Hills City Hall + Disney Hall + a European town hall that stock mismatched.
- **03 MOCA Grand Avenue — owner-OK'd CC BY-SA.** The Isozaki red-sandstone building is deliberately low/hidden and barely exists in ship-safe stock — searches returned The Broad (next door), Disney Hall, and desert "Moab." The only verified shots were Wikimedia CC. Owner chose **M32 hero + M28/M31 gallery** (all credit-required — logged in `drafts/CREDITS.md`).

## Image credits (LA batch 3)
- `moca-grand-avenue_hero.webp` — **M32, MOCA Grand Ave entrance, Minnaert, CC BY-SA 3.0** — https://commons.wikimedia.org/wiki/File:MOCA_LA_04.jpg
- `moca-grand-avenue_2.webp` — **M28, Nancy Rubins sculpture on the red wall, "vasse nicolas, antoine", CC BY 2.0** — https://commons.wikimedia.org/wiki/File:2013-07-26_MOCA_Los_Angeles_Nancy_Rubins.jpg
- `moca-grand-avenue_3.webp` — **M31, building + plaza + sculpture, Dietmar Rabich, CC BY-SA 4.0** — https://commons.wikimedia.org/wiki/File:Los_Angeles_(California,_USA),_South_Olive_Street_--_2012_--_8.jpg
- Angels Flight (05), Bradbury (06), City Hall (07): all Unsplash/Pexels — no credit.

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** MOCA → `visualArt` (contemporary art museum). Angels Flight → `culturalHeritage` (historic funicular; could be `history`). Bradbury → `architecture`. City Hall → `architecture`. Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (All batch-3 images complete.)
