# Los Angeles — tours, batch 8 (audio pending) 🌴

Image-staged 2026-07-06. Eighth LA batch — Westside icons (in progress; more tours may join).
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–7).
Tour numbers are the owner's scheme (fills 43/44).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 43 | The Getty Center | `getty-center` | 34.0780, -118.4741 | culturalHeritage | G6 (travertine campus + grand staircase) | 5 (_2 G17 Meier curved facade, _3 G14 bougainvillea, _4 G16 rampart walkway, _5 G10 travertine at night, _6 G24 steps + sculpture) |
| 44 | Rodeo Drive & Beverly Hills | `rodeo-drive` | 34.0674, -118.4019 | culturalHeritage | R2 (iconic Rodeo corner: green-domed bldg + Torso statue) | 3 (_2 R37 Via Rodeo cobbled lane, _3 R7 Via Rodeo street sign, _4 R30 "BEVERLY HILLS" garden sign) |

## Status (2026-07-06) — both image-staged + pushed to gh-pages
- Pushed at `242a90c`. **All ship-safe (Unsplash/Pexels/Pixabay) — ZERO credit obligations.**
- **43 Getty Center:** "Getty" stock is polluted with the Getty **Villa** (Roman colonnades/gardens — G22 peristyle, G33 villa garden) + a Barcelona Pavilion (G23, green marble + Kolbe statue) + Griffith Observatory + downtown aerials + Louvre Abu Dhabi dome. Verified pixels; hero G6 = the white travertine Meier campus + staircase. G25 tram (the script's opener) was offered but owner didn't pick it. **The Irwin Central Garden is NOT in the shipped set** — the search returned Villa gardens, not the Center's Central Garden; add later if wanted (owner-paste or a targeted Wikimedia pull).
- **44 Rodeo Drive:** strong pool. Dropped false matches: R28 (Prada = Las Vegas Crystals), R8 (Czech storefront). Hero R2 = the classic corner (green dome + Beverly Wilshire behind + Torso statue). Gallery leans into the script's Via Rodeo "honest masterpiece" (R37 lane + R7 sign) + the Beverly Hills garden sign (R30).

## Image credits (LA batch 8)
- **None** — all ship-safe (Unsplash/Pexels/Pixabay).

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** Getty Center → `culturalHeritage` (could be `architecture`). Rodeo Drive → `culturalHeritage` (could be `hiddenGems`/`history`). Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (Batch-8 images complete for 43/44; batch open for more tours.)
