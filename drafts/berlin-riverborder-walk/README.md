# River Border — multi-stop WALK (image-staging COMPLETE)

Where the Wall was water: Schlesisches Tor across the Oberbaumbrücke to the East Side Gallery and the riverbank park. ~2 km, level.

New image sourcing: **1 new stop image sourced (stop 3, Wikimedia CC — see CREDITS); stops 1 & 2 reuse live heroes.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (at Schlesisches Tor) (`00_schlesisches_tor.txt`) — `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–3** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 4 MP3s (intro + 3 stops); slug stems = `berlin_riverborder_multistop_00_...` … `berlin_riverborder_multistop_03_...` (the `.txt` filenames here).

## Stops → image (one per stop, in order)
| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro (at Schlesisches Tor) | `00_schlesisches_tor` | — (walk hero, below) | — | `52.50100, 13.44280` |
| 1 | Oberbaumbrücke | `01_oberbaumbruecke` | `oberbaumbruecke_hero.webp` | — | `52.50180, 13.44570` |
| 2 | East Side Gallery | `02_east_side_gallery` | `east-side-gallery_hero.webp` | — | `52.50500, 13.43940` |
| 3 | East Side Park | `03_east_side_park` | `riverborder_stop3.webp` | CC | `52.50450, 13.44300` |

- **heroImageURL (walk):** `oberbaumbruecke_hero.webp` — the fairy-tale bridge — the crossing (alt: east-side-gallery_hero).
- **additionalImageURLs** (3, in stop order): `oberbaumbruecke_hero.webp`, `east-side-gallery_hero.webp`, `riverborder_stop3.webp`.

## Wire-in checklist (when audio arrives)
1. Under maker **Atlas Studio BER** 🇩🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ber:riverborder-walk`; stops `atlas-stop:ber:…:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (drop `[beat]` lines; trim whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–3: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 3 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~2000**.
   - `centroid` (avg of the 3 geofenced stops): **`52.50377, 13.44270`**.
   - Category: `culturalHeritage`; `priceUSD: 0`; `city: "Berlin"`.
2. Credit-required stop images are logged in `drafts/CREDITS.md` (Berlin section) — surface before ship.
