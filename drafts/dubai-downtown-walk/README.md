# The Downtown Loop — 🇦🇪 Dubai multi-stop WALK (image-staging COMPLETE)

Three places to stand and one thing to look at: a lawn that gives you distance, a stretch of water that gives you a reason to stay after dark, and a bridge that gives you height. Under 2 km, level and step-free; best in the last hours of daylight.

New image sourcing: **1 new stop image staged — `dubai-downtown_stop3.webp` (Souk Al Bahar bridge, Pexels, ship-safe); stops 1–2 reuse live heroes.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (at Mall side of Burj Lake, at the footbridge) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–3** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 4 MP3s (intro + 3 stops); slug stems `dubai_downtown_multistop_00_intro` … `dubai_downtown_multistop_03_…` (the `.txt` filenames here).

## Stops → image (one per stop, in order)

| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro (Mall side of Burj Lake, at the footbridge) | `00_intro` | — (walk hero, below) | — | `25.19680, 55.27510` |
| 1 | Burj Park | `01_burj_park` | `burj-khalifa_hero.webp` | — | `25.19720, 55.27210` |
| 2 | The Dubai Fountain | `02_dubai_fountain` | `dubai-fountain_hero.webp` | — | `25.19540, 55.27460` |
| 3 | Souk Al Bahar bridge | `03_souk_al_bahar_bridge` | `dubai-downtown_stop3.webp` | — | `25.19620, 55.27340` |

- **heroImageURL (walk):** `burj-khalifa_hero.webp` — the single subject the whole loop is furnished around.
- **additionalImageURLs** (3, in stop order): `burj-khalifa_hero.webp`, `dubai-fountain_hero.webp`, `dubai-downtown_stop3.webp`.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio DXB** 🇦🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:dxb:downtown-walk`; stops `atlas-stop:dxb:downtown-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - `transcriptText` per stop = verbatim from each `.txt`, **with the header block stripped** — the Downtown and Marina & JBR scripts open with an `ATLAS — DUBAI / Walk Wn: … / Segment nn / (clean version)` block terminated by `---`; the Creek Crossing and Old Quarter scripts open with a single `DUBAI Wn — …` title line. Neither is narration. Also drop any `[beat]` lines and trim whitespace.
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–3: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 3 stop durations) — read from the delivered MP3s, do not estimate.
   - `walkingDistanceMeters`: **~1800** (the script states the distance — keep them consistent).
   - `centroidLatitude`/`centroidLongitude` (avg of the 3 geofenced stops): **`25.19627, 55.27337`**.
   - Category: `architecture`; `priceUSD: 0`; `city: "Dubai"`.
2. Credit-required images are logged in `drafts/CREDITS.md` (Dubai section) — surface before ship.
3. Master single-stop pick-map (shared heroes, coords, categories): `drafts/dubai-batch1/README.md`.
