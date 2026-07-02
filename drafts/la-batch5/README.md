# Los Angeles — tours, batch 5 (audio pending) 🌴

Image-staged 2026-07-02. Fifth LA batch — Miracle Mile museums + Griffith Park + Santa Monica.
Single-stop, geofenced. Maker **Atlas Studio LAX** (shared with batches 1–4).
Tour numbers are the owner's scheme (fills 21/22/25/29).

| # | Tour | slug | coord (lat, lon) | category | hero | gallery |
|---|------|------|------------------|----------|------|---------|
| 21 | Academy Museum of Motion Pictures | `academy-museum` | 34.0637, -118.3592 | musicAndPerformance | Y5 (Renzo Piano sphere) | 3 (_2 Y3 glass-dome, _3 Y4 terrace, _4 Y40 sphere+May Co. — CC) |
| 22 | Petersen Automotive Museum | `petersen-automotive` | 34.0619, -118.3614 | architecture | V16 (ribbon building, wide) | 2 (_2 V1 classic, _3 V7 ribbon detail) |
| 25 | Griffith Park & Greek Theatre | `greek-theatre` | 34.1197, -118.2967 | natureAndParks | R11 (park vista) | 3 (_2 R15 trail, _3 RG3 Greek seating — CC, _4 RG1 Greek concert — CC) |
| 29 | Third Street Promenade | `third-street-promenade` | 34.0168, -118.4963 | culturalHeritage | owner-supplied (topiary + promenade) | 3 (_2 owner wide-street+clock-tower, _3 Q3 dusk street, _4 Q16 plaza — both Unsplash) |

## Status (2026-07-02) — all 4 image-staged + pushed to gh-pages
- Pushed: 21/22/25 at `336b527`; 29 at `0f01128`.
- **21 Academy Museum:** Renzo Piano sphere (Y5, ship-safe) is the hero; the gold-mosaic cylinder isn't in ship-safe stock. Y40 (sphere + old May Company building) is CC BY-SA — owner chose to include it.
- **22 Petersen:** unmistakable red+silver ribbon building; deep ship-safe pool.
- **25 Griffith Park & Greek Theatre:** ⚠️ the **Greek Theatre building isn't in ship-safe stock** — searches return the Hollywood Bowl (a different venue the script name-checks). Hero = Griffith Park vista (R11, ship-safe); owner added two CC BY-SA Greek Theatre shots (RG3 seating, RG1 concert). Category `natureAndParks` (the script is mostly the wild park + P-22 mountain lion).
- **29 Third Street Promenade:** first stock set was owner-doubted → **re-sourced** (dropped car-streets/pier/beach; kept dinosaurs + car-free promenade + performers). Owner then supplied 2 of their own photos (hero = topiary + promenade; `_2` = wide street + Art Deco clock tower) + Q3/Q16 stock. Owner photos = no credit.

## Image credits (LA batch 5) — 3 CC-licensed
- `academy-museum_4.webp` (Y40) — Academy Museum sphere + May Company building — **CC BY-SA 4.0**, Wikimedia Commons (**author to confirm from the file page at ship time** — phash didn't uniquely match; the sphere has many near-identical photos).
- `greek-theatre_3.webp` (RG3) — Greek Theatre seating/stage — **User:Godfinger, CC BY-SA 3.0** — https://commons.wikimedia.org/wiki/File:Greek_Theater_2007.JPG
- `greek-theatre_4.webp` (RG1) — Greek Theatre night concert — **Amhernandez8754, CC BY-SA 4.0** — https://commons.wikimedia.org/wiki/File:The_Greek_Theatre.jpg
- Everything else in batch 5 = Unsplash/Pexels (no credit) or owner-supplied (Third Street Promenade hero + `_2`).

## Wire-in checklist (at audio arrival)
1. Maker **Atlas Studio LAX** (shared — create once at first LA wire-in).
2. Each single = `kind single`, `triggerMode geofenced`, radius 40, free, `walkingDistanceMeters null`.
3. Durations from the MP3s (mutagen). `additionalImageURLs` point at gh-pages.
4. `swift scripts/validate-tours.swift`.

**Category flags for owner review:** Academy Museum → `musicAndPerformance` (film; could be `architecture`). Petersen → `architecture`. Griffith Park & Greek Theatre → `natureAndParks` (could be `musicAndPerformance` for the theatre). Third St Promenade → `culturalHeritage`. Change if you prefer.

**Blocked on:** (1) narration MP3s; (2) Atlas Studio LAX maker. (All batch-5 images complete.)
