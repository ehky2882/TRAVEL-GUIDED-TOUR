# Los Angeles — tours, batch 8 (audio pending) 🌴

Image-staged 2026-07-06. Eighth LA batch — Westside icons + Hollywood (in progress; more tours may join).
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–7).
Tour numbers are the owner's scheme (fills 18/23/43/44).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 18 | Egyptian Theatre | `egyptian-theatre` | 34.1016, -118.3252 | musicAndPerformance | owner photo (EGYPTIAN blade sign + Grauman's forecourt gate, Hollywood Blvd) | 3 (_2 E14 palm forecourt, _3 E3 forecourt at night, _4 E23 interior auditorium) |
| 23 | Original Farmers Market & The Grove | `farmers-market-grove` | 34.0722, -118.3576 | culturalHeritage | F1 (white clock tower, close — Unsplash) | 4 (_2 WF1 clock tower, _3 F27 interior produce stall, _4 WG1 green Grove trolley, _5 GR16 Grove square + Christmas tree) |
| 43 | The Getty Center | `getty-center` | 34.0780, -118.4741 | culturalHeritage | G6 (travertine campus + grand staircase) | 5 (_2 G17 Meier curved facade, _3 G14 bougainvillea, _4 G16 rampart walkway, _5 G10 travertine at night, _6 G24 steps + sculpture) |
| 44 | Rodeo Drive & Beverly Hills | `rodeo-drive` | 34.0674, -118.4019 | culturalHeritage | R2 (iconic Rodeo corner: green-domed bldg + Torso statue) | 3 (_2 R37 Via Rodeo cobbled lane, _3 R7 Via Rodeo street sign, _4 R30 "BEVERLY HILLS" garden sign) |

## Status (2026-07-06) — all image-staged + pushed to gh-pages
- Getty + Rodeo pushed at `242a90c` (ship-safe). Egyptian Theatre pushed at `30bcdcf`.
- **23 Farmers Market & The Grove:** stock pools polluted (Seattle's Pike Place "Public Market Center", Rodeo Drive, Echo Park Lake, Angels Flight, Paramount arch, even a Lisbon tram + LA Union Station tower). Confirmed ship-safe: F1 clock tower (HERO, Unsplash), F27 interior stall (Pexels), GR16 Grove square (Pexels). The distinctive **green Grove trolley + dancing fountain + tower variants only exist under CC** — sourced from Wikimedia; owner took 2 (WF1 tower CC BY 2.5, WG1 trolley CC BY-SA 3.0 — logged below).
- **18 Egyptian Theatre:** HARD subject — **no ship-safe stock exists.** Stock pools returned real Egyptian temples (Karnak/Luxor) + every *other* Hollywood theatre (Dolby, El Capitan, Chinese, Fonda, Bruin, Orpheum) + a Disney park theatre + a Spanish market. Sourced the real thing directly from **Wikimedia Commons** (`Category:Grauman's Egyptian Theatre`); all modern color shots there are CC BY/BY-SA (credit-required), a few historical premiere shots are PD. **Owner pasted their own photo for the HERO** (ship-safe — EGYPTIAN blade sign + forecourt gate). Gallery = 3 Wikimedia CC shots (credit-required, logged below).
- **43 Getty Center:** "Getty" stock is polluted with the Getty **Villa** (Roman colonnades/gardens — G22 peristyle, G33 villa garden) + a Barcelona Pavilion (G23, green marble + Kolbe statue) + Griffith Observatory + downtown aerials + Louvre Abu Dhabi dome. Verified pixels; hero G6 = the white travertine Meier campus + staircase. G25 tram (the script's opener) was offered but owner didn't pick it. **The Irwin Central Garden is NOT in the shipped set** — the search returned Villa gardens, not the Center's Central Garden; add later if wanted (owner-paste or a targeted Wikimedia pull).
- **44 Rodeo Drive:** strong pool. Dropped false matches: R28 (Prada = Las Vegas Crystals), R8 (Czech storefront). Hero R2 = the classic corner (green dome + Beverly Wilshire behind + Torso statue). Gallery leans into the script's Via Rodeo "honest masterpiece" (R37 lane + R7 sign) + the Beverly Hills garden sign (R30).

## Image credits (LA batch 8) — 5 new
- Getty (43) + Rodeo (44): **none** — all ship-safe (Unsplash/Pexels/Pixabay).
- Egyptian Theatre (18): **hero = owner photo (no credit).** Gallery is Wikimedia CC:
  - `egyptian-theatre_2.webp` (E14, palm forecourt) — **Andreas Praefcke** / Wikimedia / **CC BY 3.0**
  - `egyptian-theatre_3.webp` (E3, forecourt at night) — **Pop Culture Geek (The Conmunity)** / Wikimedia / **CC BY 2.0**
  - `egyptian-theatre_4.webp` (E23, interior auditorium) — **Gb321** / Wikimedia / **CC BY 4.0**
- Farmers Market & The Grove (23): **hero F1 + `_3` F27 + `_5` GR16 = ship-safe (Unsplash/Pexels) — no credit.** Two Wikimedia CC:
  - `farmers-market-grove_2.webp` (WF1, clock tower) — **Infernalfox** (English Wikipedia) / **CC BY 2.5**
  - `farmers-market-grove_4.webp` (WG1, green Grove trolley) — **Clotee Pridgen Allochuku** / Wikimedia / **CC BY-SA 3.0**

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** Getty Center → `culturalHeritage` (could be `architecture`). Rodeo Drive → `culturalHeritage` (could be `hiddenGems`/`history`). Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (Batch-8 images complete for 43/44; batch open for more tours.)
