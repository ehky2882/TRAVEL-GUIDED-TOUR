# The Loop — Where the Skyscraper Was Born · 🇺🇸 Chicago WALK 2 (image-staging COMPLETE)

Between 1885 and 1893, inside four blocks, a handful of architects worked out how to hold a tall building up. Five stops, about four blocks, all sidewalk — **the intro says twenty minutes.** One question runs through all five: what holds it up — walls, a frame, or very nearly nothing.

**New image sourcing: 3 images.** Hero + stops 1 and 4. **Stops 2, 3 and 5 reuse live single-stop heroes** (the Rookery, LaSalle/Board of Trade, the Monadnock) at zero cost.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (at LaSalle & Adams) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`, plays at start.
- **Stops 1–5** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio: 6 MP3s** (intro + 5 stops); slug stems `chicago_loop_skyscraper_multistop_00_intro` … `_05_monadnock` (the `.txt` filenames here).

## Stops → image

| # | Stop | script | image | coord | note |
|---|------|--------|-------|-------|------|
| 0 | Intro (LaSalle & Adams) | `00_intro` | — (walk hero) | `41.87930, -87.63230` | manual |
| 1 | 135 S LaSalle / Home Insurance Building site | `01_home_insurance_site` | `chicago-loopskyscraper_stop1.webp` | `41.87930, -87.63230` | owner-supplied — the 1885 building itself |
| 2 | The Rookery | `02_rookery` | `the-rookery_hero.webp` | `41.87910, -87.63220` | reuses the live single hero (owner-supplied) |
| 3 | The LaSalle canyon | `03_lasalle_canyon` | `lasalle-board-of-trade_hero.webp` | `41.87990, -87.63220` | reuses the live single hero · ⚠️ vantage coord |
| 4 | Federal Plaza | `04_federal_plaza` | `chicago-loopskyscraper_stop4.webp` | `41.87920, -87.62950` | **CC — see CREDITS** · ⚠️ Calder |
| 5 | The Monadnock | `05_monadnock` | `monadnock-building_hero.webp` | `41.87830, -87.62960` | reuses the live single hero |

- **heroImageURL (walk):** `chicago-loopskyscraper_hero.webp` — the stone financial-district canyon the walk is set in. Sourced fresh; deliberately **not** any of the five stop images and not any hero already in the Chicago batch.
- **additionalImageURLs** (5, in stop order): `chicago-loopskyscraper_stop1.webp`, `the-rookery_hero.webp`, `lasalle-board-of-trade_hero.webp`, `chicago-loopskyscraper_stop4.webp`, `monadnock-building_hero.webp`.

## ⚠️ Stop 3 uses a vantage coordinate, not the landmark

The script opens *"look south down LaSalle and notice that the street ends."* That only works from **up the street** — the coordinate above is on LaSalle between Monroe and Jackson, about **230 m north of the Board of Trade itself** (`41.87785, -87.63225`). Carried across from the single-stop tour 16, which has the same issue. At the walk's 40 m radius this matters.

## ⚠️ Stop 4 — do not use the Calder

The "enormous red thing" is Alexander Calder's **Flamingo** (1974). **It is in copyright** — Calder died in 1976 — and the US has **no freedom of panorama for artworks**, so a photograph centred on it is an encumbered derivative work. **Unlike the Chicago Picasso (tour 14), there is no ruling clearing it.**

**12 of the 22 files in `Category:Federal Center (Chicago)` are Calder-dominant**, so the obvious grab is the wrong one. The staged image is Mies van der Rohe's post office and towers with the granite plaza — **buildings**, which the US architectural exemption does cover. Keep it that way.

## ⚠️ transcriptText

Header block is the `ATLAS — CHICAGO / Walk 2: … / Segment nn / Clean version` form terminated by `---`. **Start after the rule.** Beat markers are `*[beat]*` here. Same rule as the Chicago singles — see `drafts/chicago-batch1/README.md`.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio ORD** 🇺🇸, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ord:loopskyscraper-walk`; stops `atlas-stop:ord:loopskyscraper-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `totalDurationSeconds` = Σ (intro + 5 stops) — read from the delivered MP3s, do not estimate.
   - `walkingDistanceMeters`: **~550** (the intro says about four blocks; Loop blocks run ~120–140 m).
   - `centroid` (avg of the 5 geofenced stops): **`41.87916, -87.63116`**.
   - Category: `architecture`; `priceUSD: 0`; `city: "Chicago"`.
   - Tags: `District`, `Architecture`, `Engineering`, `Free to Visit`.
2. Credits: **1 new row** — `chicago-loopskyscraper_stop4.webp` (Chris Rycroft, CC BY 2.0). The hero and stop 1 are ship-safe/owner-supplied; stops 2, 3 and 5 inherit their singles' credits.
3. Master single-stop pick-map: `drafts/chicago-batch1/README.md`.
