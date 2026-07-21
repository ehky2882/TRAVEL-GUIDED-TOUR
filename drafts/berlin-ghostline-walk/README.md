# Ghost Line — following the Wall on Bernauer Strasse — multi-stop WALK (image-staging COMPLETE)

You don't cross the line, you follow it: Nordbahnhof up Bernauer Strasse to Mauerpark. ~2 km, level & free. The hardest ground, ending somewhere joyful.

New image sourcing: **4 new stop images sourced (stops 1–4, all Wikimedia CC — see CREDITS); stop 5 reuses mauerpark_hero.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–5** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 6 MP3s (intro + 5 stops); slug stems = `berlin_ghostline_multistop_00_...` … `berlin_ghostline_multistop_05_...` (the `.txt` filenames here).

## Stops → image (one per stop, in order)
| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro | `00_intro` | — (walk hero, below) | — | — |
| 1 | Nordbahnhof (ghost station) | `01_nordbahnhof` | `ghostline_stop1.webp` | CC | `52.53230, 13.38970` |
| 2 | Border strip (steel rods) | `02_border_strip` | `ghostline_stop2.webp` | CC | `52.53430, 13.38900` |
| 3 | Chapel of Reconciliation / Window | `03_chapel_window` | `ghostline_stop3.webp` | CC | `52.53500, 13.38880` |
| 4 | Memorial mile (preserved Wall) | `04_memorial_mile` | `ghostline_stop4.webp` | CC | `52.53560, 13.38900` |
| 5 | Mauerpark | `05_mauerpark` | `mauerpark_hero.webp` | — | `52.54100, 13.40220` |

- **heroImageURL (walk):** `ghostline_hero.webp` — the preserved Wall on Bernauer Strasse (CC — see CREDITS).
- **additionalImageURLs** (5, in stop order): `ghostline_stop1.webp`, `ghostline_stop2.webp`, `ghostline_stop3.webp`, `ghostline_stop4.webp`, `mauerpark_hero.webp`.

## Wire-in checklist (when audio arrives)
1. Under maker **Atlas Studio BER** 🇩🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ber:ghostline-walk`; stops `atlas-stop:ber:…:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (drop `[beat]` lines; trim whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 5 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~2000**.
   - `centroid` (avg of the 5 geofenced stops): **`52.53564, 13.39174`**.
   - Category: `history`; `priceUSD: 0`; `city: "Berlin"`.
2. Credit-required stop images are logged in `drafts/CREDITS.md` (Berlin section) — surface before ship.
