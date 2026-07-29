# Imperial Spine — Unter den Linden — multi-stop WALK (image-staging COMPLETE)

Berlin's official boulevard, west→east: the Brandenburg Gate to the palace site, in five stops. ~1.5 km, level & step-free.

New image sourcing: **none — every stop reuses a live single-stop hero.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (`00_intro.txt`) — `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–5** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 6 MP3s (intro + 5 stops); slug stems = `berlin_imperialspine_multistop_00_...` … `berlin_imperialspine_multistop_05_...` (the `.txt` filenames here).

## Stops → image (one per stop, in order)
| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro | `00_intro` | — (walk hero, below) | — | — |
| 1 | Brandenburg Gate | `01_brandenburg_gate` | `brandenburg-gate_hero.webp` | — | `52.51630, 13.37770` |
| 2 | Bebelplatz | `02_bebelplatz` | `bebelplatz_hero.webp` | — | `52.51380, 13.39400` |
| 3 | Neue Wache | `03_neue_wache` | `neue-wache_hero.webp` | (hero is CC — see CREDITS) | `52.51760, 13.39690` |
| 4 | Lustgarten (Museum Island) | `04_lustgarten` | `museum-island_hero.webp` | — | `52.51860, 13.39850` |
| 5 | Humboldt Forum | `05_humboldt_forum` | `humboldt-forum_hero.webp` | — | `52.51740, 13.40280` |

- **heroImageURL (walk):** `brandenburg-gate_hero.webp` — the front door / start of the boulevard.
- **additionalImageURLs** (5, in stop order): `brandenburg-gate_hero.webp`, `bebelplatz_hero.webp`, `neue-wache_hero.webp`, `museum-island_hero.webp`, `humboldt-forum_hero.webp`.

## Wire-in checklist (when audio arrives)
1. Under maker **Atlas Studio BER** 🇩🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ber:imperialspine-walk`; stops `atlas-stop:ber:…:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (drop `[beat]` lines; trim whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 5 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~1500**.
   - `centroid` (avg of the 5 geofenced stops): **`52.51674, 13.39398`**.
   - Category: `history`; `priceUSD: 0`; `city: "Berlin"`.
2. Credit-required stop images are logged in `drafts/CREDITS.md` (Berlin section) — surface before ship.
