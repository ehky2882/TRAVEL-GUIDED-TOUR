# Los Angeles — tours, batch 6 (audio pending) 🌴

Image-staged 2026-07-02. Sixth LA batch — Venice + Exposition Park.
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–5).
Tour numbers are the owner's scheme (fills 30/31/34/35).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 30 | Venice Beach Boardwalk | `venice-boardwalk` | 33.9850, -118.4695 | culturalHeritage | B10 (VENICE archway sign) | 5 (_2 B5 boardwalk, _3 B34 Windward colonnades, _4 B11 skate park, _5 B8 mural, _6 B20 crowd) |
| 31 | Venice Canals | `venice-canals` | 33.9825, -118.4660 | culturalHeritage | N1 (white footbridge) | 5 (_2 N17 colorful houses, _3 N7 paddler, _4 N22 dusk, _5 N5 footbridge, _6 N10 calm canal) |
| 34 | California Science Center & Space Shuttle Endeavour | `science-center-endeavour` | 34.0158, -118.2861 | history | E6 (Endeavour in pavilion) | 5 (_2 F7 kelp tank, _3 F36 winged entrance, _4 F32 bldg+garden, _5 F19 building, _6 E30 street-tow parade) |
| 35 | Natural History Museum of LA County | `natural-history-museum` | 34.0175, -118.2887 | history | H8 (dueling dinosaurs T-rex vs Triceratops) | 3 (_2 H1 dome+rose garden, _3 H7 T-rex hall, _4 H6 exterior) |

## Status (2026-07-02) — all 4 image-staged + pushed to gh-pages
- Pushed: 30/31 at `c1cf0fb`; 34/35 at `c47375f`. **All ship-safe (Unsplash/Pexels) — ZERO credit obligations.**
- **30 Venice Boardwalk / 31 Venice Canals:** deep clean ship-safe pools; verified Venice CA (not Venice Italy). Canals hero = white arched footbridge.
- **34 Science Center & Endeavour:** "California Science Center" stock returns heavy Griffith Observatory noise + a Palm Springs museum + a Texas "Science Spectrum" — verify pixels. Hero = Endeavour in the pavilion (horizontal display); the new **2024 vertical "launch position"** config (Samuel Oschin Air & Space Center) is NOT in stock yet — owner declined to paste one, kept horizontal. Gallery mixes the shuttle, the signature giant kelp tank, the winged building, and the iconic 2012 street-tow parade (E30).
- **35 Natural History Museum:** "Natural History Museum" stock mis-matches London NHM (Hintze Hall) + British Museum — verify pixels. Hero = the iconic "dueling dinosaurs." NHM **exterior is thin in stock** (dome searches return Griffith Observatory); H1 (dome+roses) + H6 (bldg+palms) are the only clean exteriors.

## Image credits (LA batch 6)
- **None** — all ship-safe (Unsplash/Pexels). Second LA batch (after b4) with zero attribution obligations.

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** Venice Boardwalk + Venice Canals → `culturalHeritage`. Science Center/Endeavour → `history` (space history; no "science" category — could be `architecture`/`hiddenGems`). Natural History Museum → `history` (natural + civic history; could be `natureAndParks`). Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (All batch-6 images complete.)
