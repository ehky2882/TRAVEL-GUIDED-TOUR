# Los Angeles — tours, batch 4 (audio pending) 🌴

Image-staged 2026-07-02. Fourth LA batch — downtown + Hollywood landmarks.
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–3).
Tour numbers are the owner's scheme (fills 10/11/14/16).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 10 | Little Tokyo | `little-tokyo` | 34.0500, -118.2400 | culturalHeritage | K1 (yagura fire tower + lanterns) | 2 (_2 K7 Japanese Village Plaza, _3 K2 lanterns) |
| 11 | The Last Bookstore | `last-bookstore` | 34.0475, -118.2497 | literature | D19 (exterior signage) | 4 (_2 D20 neon sign, _3 D7 book tunnel, _4 D9 tunnel+lamp, _5 D3 banking-hall columns) |
| 14 | Dolby Theatre | `dolby-theatre` | 34.1017, -118.3402 | musicAndPerformance | owner-supplied facade | 4 (_2 T19 red-carpet stair, _3 T1 signage, _4 T4 archway, _5 T3 complex interior) |
| 16 | Capitol Records | `capitol-records` | 34.1026, -118.3272 | architecture | P53 (aerial, Public Domain) | 1 (_2 P20 classic round tower) |

## Status (2026-07-02) — all 4 image-staged + pushed to gh-pages (`e71ed38`)
- **10 Little Tokyo — thin/noisy subject.** "Little Tokyo"/"Japanese Village" stock returned LA Chinatown, Tokyo *Japan* (Tokyo Tower/Skytree), Angels Flight, even Hollywood Blvd (El Capitan). Verified 4 genuine LA Little Tokyo (K1/K7/K2/K18); owner picked K1 hero + K7/K2. All ship-safe. (A CC-licensed JACCC/Noguchi-plaza shot exists if more are wanted later.)
- **11 Last Bookstore — deep clean ship-safe pool** (book tunnel, vortex, banking hall, signage). Owner picked exterior-signage hero.
- **14 Dolby Theatre — owner-supplied facade hero.** The only ship-safe facade shots with the "DOLBY THEATRE" sign were CC BY-SA, so owner pasted their own exterior (no credit). Gallery = ship-safe stock (red-carpet stair, signage, archway, complex interior).
- **16 Capitol Records — owner rejected the first stock set** (P16/P17/P37/P38/P39 were a *different* round tower). Correct shots were on Wikimedia; owner picked **P53 hero (Public Domain — ship-safe)** + **P20 (Pexels)** gallery. Both ship-safe. (Note: California State Capitol / US Capitol / a WV "Capitol Music Hall" all mis-matched "Capitol" — verify pixels.)

## Image credits (LA batch 4)
- **None** — all ship-safe (Unsplash/Pexels) or Public Domain or owner-supplied. Capitol hero P53 = PD (no credit); everything else ship-safe/owner. First LA batch with zero attribution obligations.

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** Little Tokyo → `culturalHeritage`. Last Bookstore → `literature`. Dolby → `musicAndPerformance`. Capitol Records → `architecture` (round-tower icon; could be `musicAndPerformance`). Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (All batch-4 images complete.)
