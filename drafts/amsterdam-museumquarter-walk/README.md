# Amsterdam — Museum Quarter multi-stop WALK (image-staging COMPLETE — zero new images)

The third Amsterdam **multi-stop walk** — the 1885–1895 culture burst on the old pasture:
Rijksmuseum → Van Gogh → Stedelijk → Concertgebouw → Vondelpark. <2 km, ~60 min, "ending on the grass."
Every stop reuses a hero already staged + live from the single-stop tours, so **no new image sourcing.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — manual trigger, `introAudioURL: null`, plays at the Rijksmuseum passage.
- **Stops 1–5** — geofenced, radius **40 m**.
- **Audio:** owner records 6 MP3s (intro + 5 stops); slug stems = the `.txt` filenames here
  (`amsterdam_museumquarter_multistop_00_intro.mp3`, `…_01_rijksmuseum.mp3`, …).

## Stops → reused hero (one image per stop, in order)
| # | Stop | script | reused image (already live) | coord |
|---|------|--------|-----------------------------|-------|
| 0 | Intro (Rijksmuseum passage) | `00_intro` | — (walk hero, below) | — |
| 1 | Rijksmuseum | `01_rijksmuseum` | `rijksmuseum_hero.webp` | `52.36000, 4.88530` |
| 2 | Van Gogh Museum | `02_van_gogh` | `van-gogh-museum_hero.webp` | `52.35840, 4.88110` |
| 3 | Stedelijk Museum | `03_stedelijk` | `stedelijk_hero.webp` | `52.35800, 4.87990` |
| 4 | Museumplein / Concertgebouw | `04_museumplein_concertgebouw` | `museumplein-concertgebouw_hero.webp` | `52.35630, 4.87910` |
| 5 | Vondelpark | `05_vondelpark` | `vondelpark_hero.webp` | `52.35810, 4.86860` |

- **heroImageURL (walk):** proposed `rijksmuseum_hero.webp` (the Cuypers "cathedral" — the walk's anchor + start). Alts: `museumplein-concertgebouw_hero.webp` or `vondelpark_hero.webp` (the ending). **Owner to confirm.**
- **additionalImageURLs** (5, in stop order): `rijksmuseum_hero.webp`, `van-gogh-museum_hero.webp`, `stedelijk_hero.webp`, `museumplein-concertgebouw_hero.webp`, `vondelpark_hero.webp`.
- **Credit:** all reused images are ship-safe stock — **no credit obligation** for this walk.

## Wire-in checklist (do when audio arrives)
1. Under maker **Atlas Studio AMS**, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ams:museum-quarter-walk`; stops `atlas-stop:ams:museum-quarter-walk:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (trim outer whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, coords above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 5 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~2000** (intro says "under two kilometres").
   - `centroid` (avg of stops 1–5): **`52.35816, 4.87880`**.
   - Category: `culturalHeritage` (or `musicAndPerformance`).
2. `swift scripts/validate-tours.swift` → fix any errors.
3. No credits to surface (all reused images are ship-safe).

## Note
- Single-stop tours reused here (Rijksmuseum #24, Van Gogh #25, Stedelijk #26, Museumplein/Concertgebouw #27,
  Vondelpark #28) stay separate; the walk has its own per-stop narration, only the images are shared.
