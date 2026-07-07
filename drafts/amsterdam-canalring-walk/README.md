# Amsterdam — Canal Ring multi-stop WALK (image-staging COMPLETE — zero new images)

The first Amsterdam **multi-stop walk**. Crosses the planned canal ring: Dam → Nine Streets →
Golden Bend → Mint Tower + flower market → Skinny Bridge. ~3 km, ~90 min. Every stop reuses a
hero already staged + live from the single-stop tours, so **no new image sourcing was needed.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — manual trigger, `introAudioURL: null`, plays at start on the Dam.
- **Stops 1–5** — geofenced, radius **40 m**.
- **Audio:** owner records 6 MP3s (intro + 5 stops); slug stems = the `.txt` filenames here
  (`amsterdam_canalring_multistop_00_intro.mp3`, `…_01_dam_square.mp3`, …).

## Stops → reused hero (one image per stop, in order)
| # | Stop | script | reused image (already live) | coord |
|---|------|--------|-----------------------------|-------|
| 0 | Intro (on the Dam) | `00_intro` | — (walk hero, below) | — |
| 1 | Dam Square & Royal Palace | `01_dam_square` | `dam-square-royal-palace_hero.webp` | `52.37310, 4.89135` |
| 2 | Nine Streets | `02_nine_streets` | `nine-streets_hero.webp` | `52.36940, 4.88680` |
| 3 | Golden Bend (Herengracht) | `03_golden_bend` | `canal-ring-golden-bend_hero.webp` | `52.36660, 4.89250` |
| 4 | Mint Tower + Bloemenmarkt (combined) | `04_munttoren_bloemenmarkt` | `muntplein-munttoren_hero.webp` (alt: `bloemenmarkt_hero.webp`) | `52.36700, 4.89250` |
| 5 | Magere Brug (Skinny Bridge) | `05_magere_brug` | `magere-brug_hero.webp` | `52.36530, 4.90180` |

- **heroImageURL (walk):** `canal-ring-golden-bend_hero.webp` (the Golden Bend — the thematic heart of the ring). Alt: `dam-square-royal-palace_hero.webp` (the start).
- **additionalImageURLs** (5, in stop order): `dam-square-royal-palace_hero.webp`, `nine-streets_hero.webp`, `canal-ring-golden-bend_hero.webp`, `muntplein-munttoren_hero.webp`, `magere-brug_hero.webp`.
- **Credit:** all reused images are ship-safe stock — **no credit obligation** for this walk.

## Wire-in checklist (do when audio arrives)
1. Under maker **Atlas Studio AMS**, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ams:canal-ring-walk`; stops `atlas-stop:ams:canal-ring-walk:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (trim outer whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, coords above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 5 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~3000** (intro says "about three kilometres").
   - `centroid` (avg of stops 1–5): **`52.36828, 4.89299`**.
   - Category: `culturalHeritage` (or `architecture`).
2. `swift scripts/validate-tours.swift` → fix any errors.
3. No credits to surface (all reused images are ship-safe).

## Note
- The single-stop tours this walk reuses (Dam Square #01, Nine Streets #11, Canal Ring/Golden Bend #10,
  Muntplein/Munttoren #15, Bloemenmarkt #14, Magere Brug #17) remain their own separate tours — the walk
  has its **own walk-specific narration** per stop (tailored to the route), only the **images** are shared.
