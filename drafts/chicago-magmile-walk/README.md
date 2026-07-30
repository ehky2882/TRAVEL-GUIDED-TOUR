# The Magnificent Mile — DuSable Bridge to the Water Tower · 🇺🇸 Chicago WALK 4 (image-staging COMPLETE)

*"In 1917, the city renamed a narrow street called Pine."* Half a mile north in four stops, from the river to an old stone water tower. The through-line: **the name arrives first and the street is rebuilt until the name is defensible** — an ordinance in 1917, a slogan in 1947, and both times the buildings came afterward to justify the label. The walk ends deliberately early, at the one thing on the avenue that nobody thought up first.

**New image sourcing: 2 files** — hero + stop 3. **Stops 1, 2 and 4 reuse live single-stop heroes** (DuSable Bridge, Wrigley/Tribune, historic Water Tower). **No credits at all.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (south end of the Michigan Avenue bridge, at Wacker Drive) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
- **Stops 1–4** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio: 5 MP3s** (intro + 4 stops); slug stems `chicago_magmile_multistop_00_intro` … `_04_water_tower`.

## Stops → image

| # | Stop | script | image | coord | source |
|---|------|--------|-------|-------|--------|
| 0 | Intro (S end of the bridge) | `00_intro` | — (walk hero) | `41.88760, -87.62430` | manual |
| 1 | The Bridge | `01_bridge` | `dusable-bridge-riverwalk_hero.webp` | `41.88760, -87.62430` | reuses the live single hero (tour 02) |
| 2 | Wrigley and Tribune | `02_wrigley_tribune` | `wrigley-tribune_hero.webp` | `41.88870, -87.62410` | reuses the live single hero (tour 06) |
| 3 | The Second Naming | `03_ontario` | `chicago-magmile_stop3.webp` | `41.89305, -87.62405` | **new** · owner-supplied |
| 4 | The Water Tower | `04_water_tower` | `historic-water-tower_hero.webp` | `41.89710, -87.62440` | reuses the live single hero (tour 05) |

- **heroImageURL (walk):** `chicago-magmile_hero.webp` — the avenue at dusk from the sidewalk, string-lit trees and shopfronts. Sourced fresh (Pexels) so the hero repeats no stop image.
- **additionalImageURLs** (4, in stop order): `dusable-bridge-riverwalk_hero.webp`, `wrigley-tribune_hero.webp`, `chicago-magmile_stop3.webp`, `historic-water-tower_hero.webp`.

## ⚠️ Stop 3 does NOT reuse `michigan-avenue-streetwall_hero` — that is the wrong street

The obvious reuse for "The Second Naming" looks like tour 12, **The Michigan Avenue Streetwall**. It is wrong and was caught only by opening the file. That single's hero is an **aerial of SOUTH Michigan Avenue across Grant Park, with Buckingham Fountain in frame** — the Grant Park cliff, about 1.5 km south of this stop. Its own coordinate gives it away: `41.88090` versus this stop's `41.89305`.

The staged image is **owner-supplied**: North Michigan Avenue at street level looking north, with the **John Hancock Center's black taper and antennae visible mid-distance** — which is the exact building the script closes the stop on (*"the black tower and its crossed steel braces you can see far up the street"*). **Do not "restore" the streetwall hero here.**

**General lesson, recorded because it applies to every walk in `drafts/`:** a reused hero must be verified by *opening the image*, never by matching the slug to the stop title. Slugs describe the single's subject, not the walk stop's vantage.

## ⚠️ The intro and stop 1 share an identical vantage

Both are "south end of the bridge, Michigan Avenue at Wacker Drive" — the same coordinate, by design; the intro orients you and stop 1 talks from the same spot. Stop 1 is geofenced, so **the listener is already inside its region when the intro ends**.

This is the AMNH stop-2 case that `ProximityMonitor` already handles (PR #251: `requestState(for:)` + `didDetermineState`, which holds an already-inside stop and plays it when the current item finishes rather than interrupting the intro). **It is not a data bug — do not separate the coordinates to "fix" it.**

## ⚠️ transcriptText — a FOURTH header format

Two differences from the other three Chicago walks:

```
ATLAS — CHICAGO
WALK 4: THE MAGNIFICENT MILE — <subtitle on the intro only>
Segment nn — <title>
Vantage: <where to stand>        ← "Vantage:", not "Voice:"
---
```

1. The fourth line is **`Vantage:`**, not `Voice:`.
2. **The `_TTS.txt` files carry no header block at all** — they are body text from the first line. The clean `.txt` files still terminate their header with the `---` rule.

`transcriptText` comes from the **clean** version, so the rule still holds: **start after `---`**. Beat markers are `*[beat]*`. See `drafts/chicago-batch1/README.md` for the two single-stop formats and the other walks' READMEs for formats two and three.

## Note — stop 1 is not a duplicate of the Riverwalk's stop 4

The DuSable Bridge appears in both walks and they share a hero, so they will sit near each other in the catalog. The scripts are genuinely different: the Riverwalk approaches from underneath and is about counterweights, trunnions and a 108-horsepower motor; this one stands on top facing north and is about Burnham and Bennett's *Plan of Chicago* and a street that ended at the water. Keep both.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio ORD** 🇺🇸, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ord:magmile-walk`; stops `atlas-stop:ord:magmile-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–4: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `totalDurationSeconds` = Σ (intro + 4 stops) — read from the delivered MP3s.
   - `walkingDistanceMeters`: **~800** (the intro says half a mile).
   - `centroid` (avg of the 4 geofenced stops): **`41.89161, -87.62421`**.
   - Category: `history`; `priceUSD: 0`; `city: "Chicago"`.
   - Tags: `District`, `History`, `Architecture`, `Commerce`, `Free to Visit`.
2. **Credits: none.** Hero is Pexels (ship-safe); stop 3 is owner-supplied. Stops 1, 2 and 4 inherit their singles' status — all three heroes are ship-safe. **Note:** tour 05's CC obligations sit on its `_2`/`_3` gallery files, *not* the hero, so reusing the hero alone inherits nothing.
3. Master single-stop pick-map: `drafts/chicago-batch1/README.md`.
