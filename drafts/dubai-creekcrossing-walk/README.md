# The Creek Crossing — 🇦🇪 Dubai multi-stop WALK (image-staging COMPLETE)

Costs about a dirham and ends at gold: the Bur Dubai Textile Souk arcade, across Dubai Creek by abra, and up into Deira where the Spice Souk and the Gold Souk sit almost door to door. ~1.2 km on foot plus the boat; level throughout.

New image sourcing: **none — every stop reuses a live single-stop hero.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (at Bur Dubai, Textile Souk entrance) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–4** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 5 MP3s (intro + 4 stops); slug stems `dubai_creekcrossing_multistop_00_intro` … `dubai_creekcrossing_multistop_04_…` (the `.txt` filenames here).

## Stops → image (one per stop, in order)

| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro (Bur Dubai, Textile Souk entrance) | `00_intro` | — (walk hero, below) | — | `25.26300, 55.29610` |
| 1 | The Textile Souk | `01_textile_souk` | `textile-souk_hero.webp` | hero is CC — see CREDITS | `25.26300, 55.29610` |
| 2 | The Abra Crossing | `02_abra_crossing` | `abra-crossing_hero.webp` | — | `25.26400, 55.29470` |
| 3 | The Spice Souk | `03_spice_souk` | `spice-souk_hero.webp` | — | `25.26810, 55.29610` |
| 4 | The Gold Souk | `04_gold_souk` | `gold-souk_hero.webp` | hero is CC — see CREDITS | `25.27140, 55.29750` |

- **heroImageURL (walk):** `abra-crossing_hero.webp` — the crossing itself — the walk's title and its hinge (alt: gold-souk_hero, the payoff).
- **additionalImageURLs** (4, in stop order): `textile-souk_hero.webp`, `abra-crossing_hero.webp`, `spice-souk_hero.webp`, `gold-souk_hero.webp`.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio DXB** 🇦🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:dxb:creekcrossing-walk`; stops `atlas-stop:dxb:creekcrossing-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - `transcriptText` per stop = verbatim from each `.txt`, **with the header block stripped** — the Downtown and Marina & JBR scripts open with an `ATLAS — DUBAI / Walk Wn: … / Segment nn / (clean version)` block terminated by `---`; the Creek Crossing and Old Quarter scripts open with a single `DUBAI Wn — …` title line. Neither is narration. Also drop any `[beat]` lines and trim whitespace.
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–4: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 4 stop durations) — read from the delivered MP3s, do not estimate.
   - `walkingDistanceMeters`: **~1200** (the script states the distance — keep them consistent).
   - `centroidLatitude`/`centroidLongitude` (avg of the 4 geofenced stops): **`25.26663, 55.29610`**.
   - Category: `culturalHeritage`; `priceUSD: 0`; `city: "Dubai"`.
2. Credit-required images are logged in `drafts/CREDITS.md` (Dubai section) — surface before ship.
3. Master single-stop pick-map (shared heroes, coords, categories): `drafts/dubai-batch1/README.md`.
