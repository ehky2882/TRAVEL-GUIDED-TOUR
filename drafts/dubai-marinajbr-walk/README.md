# Marina & JBR — An Evening in Two Waters — 🇦🇪 Dubai multi-stop WALK (image-staging COMPLETE)

Two waterfronts a few hundred metres apart: a canal the city dug for itself, and the sea it was given. The marina's western bank, the seam of footbridges at its mouth, then the beachfront boulevard. ~3.2 km, level and step-free; come for the last hour of light.

New image sourcing: **1 new stop image staged — `dubai-marinajbr_stop2.webp` (the footbridge seam, Unsplash, ship-safe); stops 1 & 3 reuse live heroes.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (at Marina promenade, western bank) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–3** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio:** 4 MP3s (intro + 3 stops); slug stems `dubai_marinajbr_multistop_00_intro` … `dubai_marinajbr_multistop_03_…` (the `.txt` filenames here).

## Stops → image (one per stop, in order)

| # | Stop | script | image | credit | coord |
|---|------|--------|-------|--------|-------|
| 0 | Intro (Marina promenade, western bank) | `00_intro` | — (walk hero, below) | — | `25.08110, 55.14060` |
| 1 | The Marina Walk | `01_marina_walk` | `marina-walk_hero.webp` | — | `25.08110, 55.14060` |
| 2 | The seam | `02_the_seam` | `dubai-marinajbr_stop2.webp` | — | `25.07800, 55.13530` |
| 3 | JBR — The Beach | `03_jbr_the_beach` | `jbr-the-beach_hero.webp` | — | `25.07740, 55.13210` |

- **heroImageURL (walk):** `marina-walk_hero.webp` — the canal side, where the walk begins (alt: jbr-the-beach_hero, the sea it opens onto).
- **additionalImageURLs** (3, in stop order): `marina-walk_hero.webp`, `dubai-marinajbr_stop2.webp`, `jbr-the-beach_hero.webp`.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio DXB** 🇦🇪, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:dxb:marinajbr-walk`; stops `atlas-stop:dxb:marinajbr-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - `transcriptText` per stop = verbatim from each `.txt`, **with the header block stripped** — the Downtown and Marina & JBR scripts open with an `ATLAS — DUBAI / Walk Wn: … / Segment nn / (clean version)` block terminated by `---`; the Creek Crossing and Old Quarter scripts open with a single `DUBAI Wn — …` title line. Neither is narration. Also drop any `[beat]` lines and trim whitespace.
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–3: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `heroImageURL` + `additionalImageURLs` per the map above.
   - `totalDurationSeconds` = Σ (intro + 3 stop durations) — read from the delivered MP3s, do not estimate.
   - `walkingDistanceMeters`: **~3200** (the script states the distance — keep them consistent).
   - `centroidLatitude`/`centroidLongitude` (avg of the 3 geofenced stops): **`25.07883, 55.13600`**.
   - Category: `architecture`; `priceUSD: 0`; `city: "Dubai"`.
2. Credit-required images are logged in `drafts/CREDITS.md` (Dubai section) — surface before ship.
3. Master single-stop pick-map (shared heroes, coords, categories): `drafts/dubai-batch1/README.md`.
