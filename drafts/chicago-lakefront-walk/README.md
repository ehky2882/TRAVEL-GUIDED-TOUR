# The Lakefront — Millennium Park to Museum Campus · 🇺🇸 Chicago WALK 3 (image-staging COMPLETE)

*"None of the ground on this walk is ground."* Some of it is a roof over a railyard; most of the rest is lake that got filled in. Five stops north to south, **about a mile and a half end to end** per the intro, flat the whole way. One question carries through: what was allowed to stand here, and what wasn't.

**New image sourcing: 1 file — the hero.** **All five stops reuse live single-stop heroes**, so this walk adds no stop images and **no credits at all**. Same pattern as Berlin's Imperial Spine.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (Millennium Park, north end, on Michigan Avenue) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
- **Stops 1–5** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio: 6 MP3s** (intro + 5 stops); slug stems `chicago_lakefront_multistop_00_intro` … `_05_museum_campus`.

## Stops → image

| # | Stop | script | image | coord | reused from |
|---|------|--------|-------|-------|-------------|
| 0 | Intro (Millennium Park, N end) | `00_intro` | — (walk hero) | `41.88300, -87.62410` | manual |
| 1 | Cloud Gate, Grainger Plaza | `01_cloud_gate` | `cloud-gate_hero.webp` | `41.88265, -87.62325` | tour 01 |
| 2 | Jay Pritzker Pavilion | `02_pritzker_pavilion` | `pritzker-pavilion_hero.webp` | `41.88250, -87.62060` | tour 10 |
| 3 | The Art Institute & Ward | `03_art_institute_ward` | `art-institute_hero.webp` | `41.87965, -87.62375` | tour 03 |
| 4 | Buckingham Fountain | `04_buckingham_fountain` | `buckingham-fountain_hero.webp` | `41.87575, -87.61885` | tour 07 |
| 5 | Museum Campus | `05_museum_campus` | `museum-campus_hero.webp` | `41.86600, -87.60600` | tour 23 |

- **heroImageURL (walk):** `chicago-lakefront_hero.webp` — the lakefront corridor from above, running south from Millennium Park toward Museum Campus. Sourced fresh so the hero isn't a repeat of any stop.
- **additionalImageURLs** (5, in stop order): `cloud-gate_hero.webp`, `pritzker-pavilion_hero.webp`, `art-institute_hero.webp`, `buckingham-fountain_hero.webp`, `museum-campus_hero.webp`.

## Note — stop 3 is about Ward, not the museum

The script's subject at stop 3 is **Aaron Montgomery Ward** and the park that was kept empty: *"the empty part is the achievement."* Ward spent twenty years and four trips to the Illinois Supreme Court keeping buildings out of Grant Park. The Art Institute hero is the right image because the museum is the thing that *was* allowed to stand — **but don't swap in a more museum-forward image later**, because the stop is about the absence of buildings, not the presence of one.

The script closes the argument itself (*"settled over a century ago and doesn't need relitigating here"*), so no sensitivity flag applies — unlike tour 02's Fort Dearborn relief.

## ⚠️ transcriptText

Header block is `ATLAS — CHICAGO / Walk 3: … / Segment nn / Clean version` terminated by `---`. **Start after the rule.** Beat markers are `*[beat]*`. See `drafts/chicago-batch1/README.md`.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio ORD** 🇺🇸, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ord:lakefront-walk`; stops `atlas-stop:ord:lakefront-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `totalDurationSeconds` = Σ (intro + 5 stops) — read from the delivered MP3s.
   - `walkingDistanceMeters`: **~2400** (the intro says about a mile and a half).
   - `centroid` (avg of the 5 geofenced stops): **`41.87731, -87.61849`**.
   - Category: `culturalHeritage`; `priceUSD: 0`; `city: "Chicago"`.
   - Tags: `Park`, `History`, `Free to Visit`, `Waterfront`.
2. **Credits: none.** Hero is ship-safe stock; every stop image inherits its single's credit status (all five are ship-safe or owner-supplied).
3. Master single-stop pick-map: `drafts/chicago-batch1/README.md`.
