# The Old Quarter — 🇦🇪 Dubai multi-stop WALK (image-staging COMPLETE)

In a city this young, “old” is a complicated word. From Al Shindagha at the creek mouth, south along the pedestrianised waterfront to Al Fahidi Fort, inland into the wind-tower lanes, and out again at Al Seef. ~2 km, level.

New image sourcing: **none — every stop reuses a live single-stop hero.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (at Al Shindagha, mouth of Dubai Creek) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–4** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 5 MP3s (intro + 4 stops); slug stems `dubai_oldquarter_multistop_00_intro` … `dubai_oldquarter_multistop_04_…` (the `.txt` filenames here).

## Stops → image (one per stop, in order)

| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro (Al Shindagha, mouth of Dubai Creek) | `00_intro` | — (walk hero, below) | — | `25.26800, 55.29010` |
| 1 | Al Shindagha | `01_al_shindagha` | `al-shindagha_hero.webp` | ⚠️ hero provenance-flagged — see batch README | `25.26800, 55.29010` |
| 2 | Al Fahidi Fort | `02_al_fahidi_fort` | `al-fahidi-fort_hero.webp` | hero is CC — see CREDITS | `25.26350, 55.29720` |
| 3 | The Al Fahidi lanes | `03_al_fahidi_lanes` | `al-fahidi_hero.webp` | — | `25.26370, 55.29790` |
| 4 | Al Seef | `04_al_seef` | `al-seef_hero.webp` | — | `25.26050, 55.29970` |

- **heroImageURL (walk):** `al-fahidi_hero.webp` — the wind-tower lanes — the quarter's emblem (alt: al-shindagha_hero, the start, but see its provenance flag).
- **additionalImageURLs** (4, in stop order): `al-shindagha_hero.webp`, `al-fahidi-fort_hero.webp`, `al-fahidi_hero.webp`, `al-seef_hero.webp`.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio DXB** 🇦🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:dxb:oldquarter-walk`; stops `atlas-stop:dxb:oldquarter-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - `transcriptText` per stop = verbatim from each `.txt`, **with the header block stripped** — the Downtown and Marina & JBR scripts open with an `ATLAS — DUBAI / Walk Wn: … / Segment nn / (clean version)` block terminated by `---`; the Creek Crossing and Old Quarter scripts open with a single `DUBAI Wn — …` title line. Neither is narration. Also drop any `[beat]` lines and trim whitespace.
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–4: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 4 stop durations) — read from the delivered MP3s, do not estimate.
   - `walkingDistanceMeters`: **~2000** (the script states the distance — keep them consistent).
   - `centroidLatitude`/`centroidLongitude` (avg of the 4 geofenced stops): **`25.26393, 55.29622`**.
   - Category: `culturalHeritage`; `priceUSD: 0`; `city: "Dubai"`.
2. Credit-required images are logged in `drafts/CREDITS.md` (Dubai section) — surface before ship.
3. Master single-stop pick-map (shared heroes, coords, categories): `drafts/dubai-batch1/README.md`.
