# Cold War Centre — multi-stop WALK (image-staging COMPLETE)

From the Cold War's emptiest ground through its darkest and most theatrical to the loveliest square Berlin owns: Potsdamer Platz → Topography of Terror → Checkpoint Charlie → Gendarmenmarkt. ~2 km, level.

New image sourcing: **none — every stop reuses a live single-stop hero.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–4** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 5 MP3s (intro + 4 stops); slug stems = `berlin_coldwarcentre_multistop_00_...` … `berlin_coldwarcentre_multistop_04_...` (the `.txt` filenames here).

## Stops → image (one per stop, in order)
| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro | `00_intro` | — (walk hero, below) | — | — |
| 1 | Potsdamer Platz | `01_potsdamer_platz` | `potsdamer-platz_hero.webp` | — | `52.50960, 13.37590` |
| 2 | Topography of Terror | `02_topography` | `topography-of-terror_hero.webp` | (hero is CC — see CREDITS) | `52.50650, 13.38300` |
| 3 | Checkpoint Charlie | `03_checkpoint_charlie` | `checkpoint-charlie_hero.webp` | — | `52.50750, 13.39040` |
| 4 | Gendarmenmarkt | `04_gendarmenmarkt` | `gendarmenmarkt_hero.webp` | — | `52.51370, 13.39270` |

- **heroImageURL (walk):** `checkpoint-charlie_hero.webp` — the iconic Cold War crossing (alt: gendarmenmarkt_hero, the finale).
- **additionalImageURLs** (4, in stop order): `potsdamer-platz_hero.webp`, `topography-of-terror_hero.webp`, `checkpoint-charlie_hero.webp`, `gendarmenmarkt_hero.webp`.

## Wire-in checklist (when audio arrives)
1. Under maker **Atlas Studio BER** 🇩🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ber:coldwarcentre-walk`; stops `atlas-stop:ber:…:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (drop `[beat]` lines; trim whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–4: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 4 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~2000**.
   - `centroid` (avg of the 4 geofenced stops): **`52.50932, 13.38550`**.
   - Category: `history`; `priceUSD: 0`; `city: "Berlin"`.
2. Credit-required stop images are logged in `drafts/CREDITS.md` (Berlin section) — surface before ship.
