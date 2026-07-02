# Los Angeles — tours, batch 1 (audio pending) 🌴

Image-staged 2026-07-02. **First LA batch** — downtown-cultural + Hollywood icons.
Single-stop, geofenced. Maker **Atlas Studio LAX** (create at first LA wire-in).
Sourced no-gate + Wikimedia-verified; owner picked. Images live on gh-pages.

Tour numbers are the owner's scheme (gaps 03/05/06/07/10/11/14 not yet sent).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 01 | Walt Disney Concert Hall | `walt-disney-concert-hall` | 34.0553, -118.2498 | architecture | WD1 | 6 (_2 WD13, _3 WD24, _4 WD19, _5 WD67, _6 WD53, _7 WD37) |
| 02 | The Broad | `the-broad` | 34.0546, -118.2507 | visualArt | TB25 | 3 (_2 TB240, _3 TB224, _4 TB230) |
| 04 | Grand Central Market | `grand-central-market` | 34.0507, -118.2489 | culturalHeritage | GC1 | 1 (_2 GC16) |
| 08 | Union Station | `la-union-station` | 34.0561, -118.2365 | architecture | US7 | 1 (_2 US12) |
| 09 | El Pueblo / Olvera Street | `el-pueblo-olvera-street` | 34.0574, -118.2378 | culturalHeritage | **PENDING owner paste** | — |
| 12 | Hollywood Walk of Fame | `hollywood-walk-of-fame` | 34.1016, -118.3269 | culturalHeritage | HW16 | 2 (_2 HW19, _3 HW1) |
| 13 | TCL / Grauman's Chinese Theatre | `tcl-chinese-theatre` | 34.1022, -118.3410 | architecture | CT38 | 1 (_2 CT4) |
| 15 | Hollywood Sign | `hollywood-sign` | 34.1341, -118.3215 | culturalHeritage | HS1 | 3 (_2 HS3, _3 HS8, _4 HS5) |

## Status (2026-07-02)
- **DONE + pushed to gh-pages:** 01, 02, 04, 08, 12, 13, 15 (7 tours). Heroes + galleries all cropped and live.
- **PENDING: 09 El Pueblo / Olvera Street.** Owner is supplying their own photos (wants one of the *street* shots as hero). **No images cropped/pushed yet.** Note for next session: stock badly misfired here (returned Paramount Studios / Universal / Broadway, all wrong); the only genuine catalog options were Wikimedia CC BY 3.0 (OV60/61/62/63/67) or a PD postcard (OV59) — owner opted to paste their own instead. **Action: extract owner's Olvera Street pastes from transcript, crop street-as-hero, push, then this batch is complete.**

## Image credits (LA batch 1 — ONE credit only)
- `walt-disney-concert-hall_6.webp` (WD53, the "french-fry organ") — Daniel Hartwig, **CC BY 2.0** — https://commons.wikimedia.org/wiki/File:Disney_Concert_Hall_(10920404614).jpg
- Everything else in this batch is ship-safe (Unsplash/Pexels) or CC0/Public-Domain:
  - `walt-disney-concert-hall_5.webp` (WD67, concert room) = CC0 — no credit
  - `tcl-chinese-theatre_hero.webp` (CT38) = Public Domain — no credit
  - The Broad TB240 (_2) = CC0; all other picks = Unsplash/Pexels — no credit
- (El Pueblo credits TBD once owner's pastes are cropped — owner-supplied = no credit.)

## Wire-in checklist (at audio arrival)
1. Create **Atlas Studio LAX** maker (first LA wire-in — shared by all LA tours).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` already point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Blocked on:** (1) narration MP3s; (2) the Atlas Studio LAX maker; (3) El Pueblo images (09).
