# Link pins join "More like this" — and the exclusion that was never measured

**Session 114 · branch `claude/open-source-ai-integration-pxuxdh` · content + scripts + one Swift line**

Owner asked, of the section that shipped hours earlier in #915: *"so do 'more
like this' not show up for 'pinned' tours (instagram, tiktok, etc)... can it?"*

It could. The reason it did not was a sentence nobody had checked.

---

## The correction

#915 excluded link pins on the stated grounds that **"a pin has no transcript,
so its vector is near-meaningless."** That was written into a code comment, into
`docs/lessons.md`, into the PR body and into the handoff, and it was never
measured. Measured now:

| | |
|---|---|
| Pins carrying title, both descriptions, tags, city, country, stop caption | **2,318 of 2,318** |
| Median characters per pin | **540** (p10 311, p90 1,229) |
| Missing field | `transcriptText` only — and #795 took that off the wire **for tours too** |

A 120-pin probe against all tours: median best match **0.505**, 88 of 120 above
the 0.45 floor. Strong where Atlas has coverage (a Tempelhof pin → Tempelhofer
Feld, 0.644), correctly silent where it does not (a Toronto BBQ pin's best match
was a Sydney restaurant at 0.413, under the floor).

**The exclusion cost a whole feature on 2,318 entries, for a reason that took
four minutes to disprove.**

⚠️ `load_catalog()` only ever read `data["tours"]`, so pins were never embedded
at all — the `eligible` mask the comment defended was **dead code**.

## What the owner decided

Two questions, both put with numbers attached:

1. **Both directions** — *"pin pages can recommend tours, and tour pages can
   recommend pins."*
2. **Pins may match other pins too**, after that turned out to be a third
   direction rather than part of the first two.

The one asymmetry kept: **a pin takes no cross-city fill.** A tour that runs out
of same-city neighbours fills from elsewhere; a pin does not, because 978 pins
sit in a city where Atlas has no tours at all and the fill would offer someone
standing in Prague a walk in Vienna.

## The third direction, which is the thing to remember

"Pins suggest tours, tours suggest pins" sounds like two directions. It is
**three** — a pin's same-city candidates include other pins — and that third one
dominated the run:

| | |
|---|---|
| Pins that gained a section | **1,902 of 2,318 (82%)** |
| …whose list is **only other creators' posts** | **1,322** |
| …with at least one real Atlas tour | **580** |
| Pin references appearing under tours | **790** |

The first draft of this work was going to be reported as "what you asked for".
It was priced and put back to the owner instead, who chose the wider version
knowingly.

## Egress — measured on the live payload, gzip level 1

| | bytes | pins covered |
|---|---|---|
| Today (pins excluded) | 2,885,384 | 0 |
| Pins may name tours only | 2,932,051 | 580 |
| **Pins may name pins too — shipped** | **3,176,601** | **1,902** |

**+291 KB** over today. The estimate made beforehand from average id length was
~253 KB — close enough to sound right, far enough to have argued the wrong case.
🔴 Re-measure; do not quote these. Level 1 because that is what PostgREST uses.

## Numbers from the run

- 3,900 entries · 9,644 chunks · **3,482 (89%) have at least one neighbour**
- **23,951 references**, 1,407 cross-city (6%) — all cross-city ones belong to tours
- 2,313 of 3,900 entries changed; 418 will hide the section
- `validate-tours-mirror.py`: **37/37 injected faults caught, control clean,
  0 errors** over 1,582 tours + 2,318 pins + 307 places

## Files

- **`scripts/build-embeddings.py`** — `load_catalog` merges `linkPins` (mirroring
  `ToursData`); `related_tours` drops the eligibility mask and gains the
  no-cross-city-fill rule for pins; `apply_related` patches both arrays;
  30 self-tests, 5 of them new.
- **`scripts/validate-tours.swift`** — the three #915 rules inverted, plus a new
  one: **a pin's neighbours must all share its city.** That is the only
  mechanical guard on the no-fill rule.
- **`scripts/validate-tours-mirror.py`** — the #915 rules were **never mirrored
  here at all**, so every one of them passed locally and only CI could see them.
  Now mirrored, with 5 injected-fault cases. The fourth session in a row to find
  an unmirrored rule (143, 146, 148, this one).
- **`TRAVEL GUIDED TOUR/Features/Tour/TourDetailView.swift`** — `nearbySubtitleText`
  no longer formats a duration for a pin. Every pin carries
  `totalDurationSeconds: 0`, so the row read `"· 0.8 mi away"` with a dangling
  separator. **This was already live in "Nearby Tours"** — `toursNearby` never
  filtered pins — so it is a pre-existing bug fixed here, not one introduced.

## What needed no work, and why

- `DataService.relatedTours(for:)` — `tourById` is built from the merged list, so
  a pin id already resolved.
- `moreLikeThisSection` — a pin's detail page already runs all three tail
  sections; the `isLink` branch only swaps `stopsSection` for `creditSection`.
- **No SQL.** Pins are ordinary `tours` rows with `kind='link'`;
  `related_tour_ids` is already a column and already in `get_catalog_core_base`.
  A content merge is the whole deployment.

## Still open

- **36 tours keep no `createdAt`** (35 are all of Atlas Studio SFO; shallow clone
  stops at 2026-08-17). Unchanged from #915.
- **The owner's device check** of the section on build 162 — now with pins to
  look at as well. No new build is needed for the data; the subtitle fix is
  Swift and does need one.
