# Los Angeles — tours, batch 2 (audio pending) 🌴

Image-staged 2026-07-02. Second LA batch — mid-city museums + hilltop/coast icons.
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batch 1).
Tour numbers are the owner's scheme (batch 1 = 01/02/04/08/09/12/13/15).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 19 | LACMA / David Geffen Galleries | `lacma-geffen-galleries` | 34.0639, -118.3592 | visualArt | owner-supplied Zumthor bldg (ribbon across Wilshire + Urban Light) | 3 (_2 owner ribbon-underside detail, _3 L25, _4 L27 Urban Light night, Pexels) |
| 20 | La Brea Tar Pits | `la-brea-tar-pits` | 34.0638, -118.3556 | natureAndParks | owner-OK'd CC BY-SA (W8, Lake Pit mammoths) | none (hero-only, owner decision) |
| 24 | Griffith Observatory | `griffith-observatory` | 34.1184, -118.3004 | architecture | G1 (aerial dusk, Unsplash) | 5 (_2 G4, _3 G5, _4 G31, _5 G32, _6 G22) |
| 28 | Santa Monica Pier | `santa-monica-pier` | 34.0083, -118.4983 | culturalHeritage | S14 (pier at dusk, Unsplash) | 5 (_2 S3, _3 S8, _4 S6, _5 S2, _6 S52) |

## Status (2026-07-02) — BATCH 2 IMAGE-STAGING COMPLETE (all 4 tours)
- **DONE + pushed to gh-pages:** 24 Griffith (hero+5), 28 Santa Monica (hero+5), 20 La Brea (hero only) at `ea793bb`; 19 LACMA (hero+3) at `72c0176`.
- **19 LACMA — DONE (owner-supplied Zumthor building).** Owner pasted 2 photos of the finished David Geffen Galleries: hero = the concrete ribbon spanning across Wilshire with Urban Light in front (the recognizable establishing shot); `_2` = the curved concrete-underside detail with the black faceted sculpture + plaza. `_3`/`_4` = L25/L27 Urban Light night (Pexels). Owner photos = no credit. (The finished building still isn't in the free/stock/Wikimedia pool — only a construction shot existed there — so owner-supplied was the right call.)
- **20 La Brea — image-sourcing was hard.** Stock (Unsplash/Pexels/Pixabay) for "La Brea Tar Pits" returned WRONG museums (a European mammoth museum, a beaux-arts hall like AMNH, in-situ digs under wooden beams) — mammoth skeletons look alike across museums, so tags can't be trusted; verify pixels. Wikimedia Commons had the correct iconic shots but **all the good ones are CC BY-SA** (credit-required); only PD option was a weak historic B&W. Owner OK'd **W8 (CC BY-SA 4.0, Downtowngal)** as hero and chose **hero-only** (no gallery). Interiors (dire-wolf-skull wall, Smilodon, mammoth mounts — N-series) were offered but declined.
## Image credits (LA batch 2)
- `la-brea-tar-pits_hero.webp` — **W8, La Brea Tar Pits (Lake Pit), Downtowngal, CC BY-SA 4.0** — https://commons.wikimedia.org/wiki/File:La_Brea_Tar_Pits_January_2021.jpg — **CREDIT REQUIRED** (see `drafts/CREDITS.md`; needs the pending attribution-UI before LA ships live).
- Griffith (24) + Santa Monica (28): all Unsplash/Pexels — ship-safe, no credit.
- LACMA (19): L25/L27 = Pexels (no credit); hero = owner-supplied (no credit).

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared with batch 1 — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** La Brea → `natureAndParks` (Ice-Age park/fossil site; no "science" category exists — could also be `history`). Griffith → `architecture` (art-deco landmark; could be `hiddenGems`/science-leaning). Santa Monica Pier → `culturalHeritage` (beloved historic landmark). Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (All batch-2 images complete.)
