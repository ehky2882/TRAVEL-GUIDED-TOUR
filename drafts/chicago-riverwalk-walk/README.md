# The Riverwalk · 🇺🇸 Chicago WALK 1 (image-staging COMPLETE)

*"A mile and a quarter, a staircase at every bridge, and a river that has been running the wrong way on purpose since 1900."* Five stops west to east along the south bank of the main branch, Lake Street to Lake Michigan. One idea holds it together: **every stop is a decision about water** — which way it goes, how high it sits, what gets built on it, who may cross it and when. None of it natural; all of it decided by somebody, usually in an argument.

**New image sourcing: 4 files** — hero + stops 1, 2, 5. **Stops 3 and 4 reuse live single-stop heroes** (Marina City, DuSable Bridge). **No credits at all** — every image is Unsplash, Pexels, or US-federal public domain.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (top of the Lake Street stairway, west end of the Riverwalk) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
- **Stops 1–5** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio: 6 MP3s** (intro + 5 stops); slug stems `chicago_riverwalk_multistop_00_intro` … `_05_harbor_lock`.

## Stops → image

| # | Stop | script | image | coord | source |
|---|------|--------|-------|-------|--------|
| 0 | Intro (Lake St stairway, W end) | `00_intro` | — (walk hero) | `41.88600, -87.63750` | manual |
| 1 | Wolf Point & the Merchandise Mart | `01_wolf_point_mart` | `chicago-riverwalk_stop1.webp` | `41.88760, -87.63490` | **new** · Pexels |
| 2 | The Eastland | `02_eastland` | `chicago-riverwalk_stop2.webp` | `41.88670, -87.63170` | **new** · US Coast Guard, PD |
| 3 | Marina City | `03_marina_city` | `marina-city_hero.webp` | `41.88700, -87.62880` | reuses the live single hero (tour 06) |
| 4 | DuSable Bridge | `04_dusable_bridge` | `dusable-bridge-riverwalk_hero.webp` | `41.88800, -87.62450` | reuses the live single hero (tour 02) |
| 5 | The Chicago Harbor Lock | `05_harbor_lock` | `chicago-riverwalk_stop5.webp` | `41.88860, -87.61760` | **new** · Pexels |

- **heroImageURL (walk):** `chicago-riverwalk_hero.webp` — the main branch from above, bascule bridges stacked into the distance with the Merchandise Mart on the left bank. Sourced fresh so the hero repeats no stop image.
- **additionalImageURLs** (5, in stop order): `chicago-riverwalk_stop1.webp`, `chicago-riverwalk_stop2.webp`, `marina-city_hero.webp`, `dusable-bridge-riverwalk_hero.webp`, `chicago-riverwalk_stop5.webp`.

## ⚠️ Sensitivity — stop 2 (the Eastland)

The script carries its own header flag: **`SENSITIVITY: Docket item 3. One reverent treatment corpus-wide. NO mortality figure. No method detail.`** Honor it in every downstream surface — do not add a death toll to the tour description, the stop title, or any marketing copy.

**The image was chosen under the same rule.** It comes from Commons `Category:Eastland disaster memorials` — a US Coast Guard crew laying a wreath on the water at the annual July 24th commemoration — and **deliberately not** from `Category:Eastland disaster`, which holds 1915 press photographs of the recovery, including the dead. **Do not re-source this stop from that category.** The script ends on the anniversary and the flowers going over the railing; the image is that same moment.

## ⚠️ Vantage — stops 1, 3 and 5 geofence where the listener stands

Three coords are the *listening position on the south bank*, not the subject:

- **Stop 1** stands between Franklin and Wells and looks northwest across the water at Wolf Point (~150 m away) and the Mart's far bank.
- **Stop 3** stands between Dearborn and State; Marina City is on the **north** bank opposite (~120 m).
- **Stop 5** stands under the Lake Shore Drive bridge; the lock itself is ~600 m further east in open water and is explicitly unreachable — *"You can see it from here; you can't walk out to it."*

Do not "correct" these to the landmark coordinates — the geofence has to fire where the listener actually is, on the path.

## ⚠️ transcriptText — third header format

This walk's header block is **four lines**, one more than the other two Chicago walks, and two of the six scripts carry an extra flag line:

```
ATLAS — CHICAGO
WALK 1: THE RIVERWALK
Segment nn — <title>
Voice: American register. Clean version.
[SENSITIVITY: … ]        ← stop 02 only
[DEVICE PAYOFF: … ]      ← stop 05 only
---
```

**Start `transcriptText` after the `---` rule** — never count header lines, since the count varies. Beat markers are `*[beat]*`. Note stop 05 also carries `FINAL SEGMENT — no hand-off` on the Voice line. See `drafts/chicago-batch1/README.md` for the two formats used by the single-stop batch.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio ORD** 🇺🇸, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ord:riverwalk-walk`; stops `atlas-stop:ord:riverwalk-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–5: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `totalDurationSeconds` = Σ (intro + 5 stops) — read from the delivered MP3s.
   - `walkingDistanceMeters`: **~2000** (the intro says a mile and a quarter).
   - `centroid` (avg of the 5 geofenced stops): **`41.88758, -87.62750`**.
   - Category: `history`; `priceUSD: 0`; `city: "Chicago"`.
   - Tags: `Waterfront`, `Bridge`, `History`, `Engineering`, `Free to Visit`.
2. **Credits: none.** Hero and stops 1 + 5 are Unsplash/Pexels (ship-safe, no attribution). Stop 2 is a **US Coast Guard work in the public domain** — SHA-1 verified against Commons (`Coast_Guard_participates_in_SS_Eastland_memorial_in_Chicago_130724-G-ZZ999-001.jpg`, CPO Alan Haraf, PD) — so it carries **no** obligation either. Stops 3 and 4 inherit their singles' status (both ship-safe).
3. Master single-stop pick-map: `drafts/chicago-batch1/README.md`.
