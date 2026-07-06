# Los Angeles — tours, batch 7 (audio pending) 🌴

Image-staged 2026-07-06. Seventh LA batch — Exposition Park stadium + Pasadena/San Marino cluster.
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–6).
Tour numbers are the owner's scheme (fills 36/39/40/41).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 36 | Los Angeles Memorial Coliseum | `la-coliseum` | 34.0141, -118.2879 | history | C18 (peristyle end / torch) | 4 (_2 C17, _3 C19, _4 C20, _5 C21) |
| 39 | The Huntington | `the-huntington` | 34.1291, -118.1146 | culturalHeritage | UW2 (Art Gallery front facade) | 3 (_2 U6 Chinese garden, _3 U9 Chinese garden, _4 U8 Japanese garden) |
| 40 | Gamble House | `gamble-house` | 34.1547, -118.1607 | architecture | DW20 (front elevation) | 3 (_2 DW8, _3 DW7, _4 DW22) |
| 41 | Old Pasadena | `old-pasadena` | 34.1458, -118.1503 | culturalHeritage | O2 (Colorado Blvd corner Beaux-Arts bldg) | 2 (_2 O16 ornate balcony facade, _3 O17 "OLD TOWN" street clock) |

## Status (2026-07-06) — all 4 image-staged + pushed to gh-pages
- **36 Coliseum:** all ship-safe (Pexels). Hero + 4 gallery. Owner: "use all, C18 as hero."
- **39 The Huntington:** hero re-sourced — the mansion is the **Huntington Art Gallery** (beige Beaux-Arts residence, wide front lawn). First candidate (Wrigley Mansion, green tile roof + curved drive) was owner-doubted and correctly excluded. Hero UW2 = **Wikimedia CC BY-SA 3.0 (Matthew Field)** — credit obligation. Gallery U6/U9/U8 = Unsplash (ship-safe).
- **40 Gamble House:** hero + 3 gallery. **3 of 4 are CC BY-SA (Wikimedia)** — DW20/DW7 Cullen328 (BY-SA 3.0), DW8 Codera23 (BY-SA 4.0); DW22 is Public Domain (no credit). Stock pool was polluted with "gambling" images — verified pixels.
- **41 Old Pasadena:** hard stock subject — most candidates were look-alikes (Mexican colonial streets, downtown LA's Broadway/Globe Theatre, Hollywood backlots, Chinatown, Olvera St). Only 3 location-confirmed: O2 (Colorado Blvd corner, street sign visible — HERO), O16 (ornate balcony facade), O17 ("OLD TOWN" clock). All ship-safe (Unsplash/Pexels).

## Image credits (LA batch 7) — 4 new attribution obligations
- `the-huntington_hero.webp` — **Matthew Field (Mfield)** / Wikimedia Commons / **CC BY-SA 3.0**
- `gamble-house_hero.webp` — **Cullen328** / Wikimedia Commons / **CC BY-SA 3.0**
- `gamble-house_2.webp` — **Codera23** / Wikimedia Commons / **CC BY-SA 4.0**
- `gamble-house_3.webp` — **Cullen328** / Wikimedia Commons / **CC BY-SA 3.0**
- (`gamble-house_4.webp` — Mattnad / Wikimedia / Public Domain — no credit needed)

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** Coliseum → `history` (could be `architecture`). The Huntington → `culturalHeritage` (library + art + gardens; could be `natureAndParks` for the gardens). Gamble House → `architecture`. Old Pasadena → `culturalHeritage` (could be `history`). Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (All batch-7 images complete.)
