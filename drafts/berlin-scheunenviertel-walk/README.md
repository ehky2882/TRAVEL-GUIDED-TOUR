# Scheunenviertel — the barn quarter — multi-stop WALK (image-staging COMPLETE)

The old Jewish quarter, courtyard to courtyard: a polished one, a rough one, then a street heavy with memory — ending at the golden dome. Well under 1 km, level.

New image sourcing: **2 new stop images sourced (stops 2 & 3, Wikimedia CC — see CREDITS); stops 1 & 4 reuse live heroes.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure
- **kind:** `multiStop`
- **Stop 0 = intro** (at Hackescher Markt) (`00_hackescher_markt.txt`) — `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–4** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 5 MP3s (intro + 4 stops); slug stems = `berlin_scheunenviertel_multistop_00_...` … `berlin_scheunenviertel_multistop_04_...` (the `.txt` filenames here).

## Stops → image (one per stop, in order)
| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro (at Hackescher Markt) | `00_hackescher_markt` | — (walk hero, below) | — | `52.52400, 13.40240` |
| 1 | Hackesche Höfe | `01_hackesche_hoefe` | `hackesche-hoefe_hero.webp` | (hero is CC — see CREDITS) | `52.52510, 13.40240` |
| 2 | Haus Schwarzenberg | `02_haus_schwarzenberg` | `scheunenviertel_stop2.webp` | CC | `52.52530, 13.40300` |
| 3 | Große Hamburger Strasse | `03_grosse_hamburger_strasse` | `scheunenviertel_stop3.webp` | CC (deportation memorial — dignified) | `52.52450, 13.39800` |
| 4 | Neue Synagoge | `04_neue_synagoge` | `neue-synagoge_hero.webp` | (hero is CC — see CREDITS) | `52.52470, 13.39350` |

- **heroImageURL (walk):** `neue-synagoge_hero.webp` — the golden dome — the walk's destination (owner-confirmed default; alt: hackesche-hoefe_hero, the start).
- **additionalImageURLs** (4, in stop order): `hackesche-hoefe_hero.webp`, `scheunenviertel_stop2.webp`, `scheunenviertel_stop3.webp`, `neue-synagoge_hero.webp`.

## Wire-in checklist (when audio arrives)
1. Under maker **Atlas Studio BER** 🇩🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ber:scheunenviertel-walk`; stops `atlas-stop:ber:…:<n>` (uuid5).
   - `transcriptText` per stop = verbatim from each `.txt` (drop `[beat]` lines; trim whitespace).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–4: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 4 stop durations) — read from the MP3s at wire-in.
   - `walkingDistanceMeters`: **~800**.
   - `centroid` (avg of the 4 geofenced stops): **`52.52490, 13.39923`**.
   - Category: `culturalHeritage`; `priceUSD: 0`; `city: "Berlin"`.
2. Credit-required stop images are logged in `drafts/CREDITS.md` (Berlin section) — surface before ship.
