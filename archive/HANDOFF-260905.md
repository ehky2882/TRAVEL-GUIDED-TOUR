# HANDOFF — 2026-09-05 (session 144)

**Thirteen Studio Gang link pins across eight buildings, four heroes that are not
photographs, and two stack-cap findings.** Branch `claude/new-tour-links-nl8h63`, cut clean
at `main`'s tip (`89bb15c8`). Content only — no Swift, no SQL, no build.

**linkPins 1,201 → 1,214 · makers 328 → 331 · `tours` and `places` byte-identical.**

---

## What arrived

Fifteen Instagram links under a heading reading **"Studio Gang"**. Two were pasted twice, so
**13 distinct posts**, and **0 were already in the catalogue**. Mixed paths — 9 `/reel/`,
5 `/p/`, 1 `/tv/`.

⚠️ **All three path shapes were verified against `LinkSource.embedURL` in the Swift, not
assumed from the doc.** It matches `p`, `reel` and `tv`, and the embed keeps the path segment
(`/tv/{code}/embed`), so all 13 are structurally pinnable. **A TikTok `/photo/` URL still
cannot be** — do not conflate the two.

**All 13 alive, none blocked.** Every embed returned **256–263 KB with `contextJSON` present**,
against **three already-live catalogue pins fetched in the same pass with the same UA at
256–262 KB**. Byte size is only a heuristic; the verdict is `contextJSON`.

---

## ⚠️ The heading is loose — again

The session-135 *read the payload, not the heading* rule, live for the third batch running.
**Eleven posts are `@studiogang`; two are not:**

| Post | Account | What it is |
|---|---|---|
| `CmPMA9CgJUl` | **`@11hoytbk`** | 11 Hoyt's own building account |
| `CjarNZrJrt6` | **`@arkmfa`** | the Arkansas Museum of Fine Arts' own account |

Both are real posts about real Studio Gang buildings, so both ship (the venue's-own-account
class — the Coca-Cola / GVA Lighting precedent). **3 new maker rows**, all Instagram, all
shipping `avatarURL: null` by design.

**Denver, Little Rock and St. Louis are new to the catalogue.** No new country — all 13 are
`United States`.

---

## Eight subjects, four of them pinned more than once

| Subject | City | Posts |
|---|---|---|
| **Arkansas Museum of Fine Arts** | Little Rock | **4** |
| Populus | Denver | 2 |
| Solar Carve / 40 Tenth Avenue | New York | 2 |
| Spelman College Center for Innovation and the Arts | Atlanta | 1 |
| 11 Hoyt | Brooklyn | 1 |
| The Gilder Center | New York | 1 |
| Mira | San Francisco | 1 |
| One Hundred | St. Louis | 1 |

⚠️ **The fourth AMFA post calls it the "Arkansas Arts Center"** — the museum's name before the
2021 rename, and the post is the 2018 first-look at the transformation. It ships as
**`Transforming the Arkansas Arts Center`**, keeping the then-name honestly rather than
back-dating the new one onto a seven-year-old announcement.

---

## 🔴 TWO STACK-CAP FINDINGS — the AMFA one is where the cap actually bites

Read from the Swift, not assumed: **`TourSetMap.maxStacked = 3`** (maker page, place page,
list page) and **`HomeView.maxStackedPlacecards = 4`** (Home map).

**AMFA is FOUR markers on one coordinate.** Home renders all four with **no headroom**;
`TourSetMap` renders **three, and the fourth is permanently unreachable** — silently, with no
error. Three of the four are `@studiogang`, so on that creator's own maker page the stack sits
exactly at the cap with nothing to spare.

**The Gilder Center is effectively THREE deep.** Two pins already existed there —
`@archiwhisperer`'s *The Gilder Center* and `@archimarathon`'s *Inside the Gilder Center* —
and this batch adds a third. ⚠️ **`check-place-candidates.py` only reports two of the three**:
the existing pair differs in the **6th/7th decimal** (40.78158 vs 40.7815797), which defeats
the EXACT tier's equality test — the documented CalAcademy rounding artifact, the same shape
that hid Museum Station last session. On the map all three are 0.03 m apart.

**Both are place candidates and both are the owner's call.** A place collapses its members into
one capsule pin carrying `placeTourCount`, so the cap stops applying — the 120 Broadway /
Alwyn Court fix. **Flagged, not created**: a place needs its own copy, address, photograph and
approval.

🔴 **Nothing was nudged together to manufacture a group, and nothing nudged apart to dodge
one.** Every coordinate came from an independent geocode; `check-place-candidates.py` goes
**12 EXACT → 16** with **NEAR unchanged at 53**, and the diff proves the four added groups are
exactly Populus, AMFA, Solar Carve and the Gilder Center.

---

## Coordinates — every one reverse-verified at zoom 18

| Subject | Coordinate | How it was settled |
|---|---|---|
| Populus | `39.7403544, -104.9911197` | forward names `Populus Denver` at 240 14th St; reverse lands on **Pasque**, the restaurant inside it (inner-tenant) |
| AMFA | `34.7383258, -92.2663529` | reverses **by name**: `Arkansas Museum of Fine Arts, 501 East 9th Street` |
| 11 Hoyt | `40.6897869, -73.9853461` | reverses to **Taim** at **11 Hoyt Street** — inner tenant at the building's own number |
| Gilder Center | `40.78158, -73.974641` | reverses **by name** to `Richard Gilder Center…, 200 Central Park West`; converges on the existing pins' point |
| Mira | `37.7899673, -122.3917231` | OSM names **`MIRA`** exactly; ⚠️ reverse lands on 120 Folsom, the nearest addressed node |
| One Hundred | `38.6427365, -90.2646384` | reverses **by name** to `100 Above the Park` — OSM's name for the building Studio Gang calls One Hundred |
| Solar Carve | `40.7414821, -74.0084598` | reverses to the address point **40, 10th Avenue**, the caption's own number |
| Spelman Center | `33.7446799, -84.4135812` | see below |

⚠️ **Re-querying was the whole fix twice.** `Mira, 280 Spear Street` and every Spelman phrasing
returned **0 results** on the first pass; `Mira Tower, San Francisco` and `Spelman College`
found both instantly. **A first-pass miss is not evidence a place is unmapped.**

🔴 **Spelman was the Warehaus interpolation trap.** `350 Spelman Lane SW` returns **three**
house points spread ~280 m — so the number is interpolated, not a mapped building. A **bounded
viewbox** search around the campus found the real thing: **`Spelman College Center for
Innovation and the Arts`**, `amenity/arts_centre`, named almost exactly. ⚠️ Its reverse lands
on an unnamed **loading dock** at 407 Westview Drive — the documented nearest-addressed-node
case (Tribune Tower had the identical shape), so it was **proved forward**.

⚠️ **11 Hoyt ships `city: "Brooklyn"` and that is a judgement.** The dominant link-pin
convention is `New York` (94 Brooklyn-coordinate pins vs 10), but the caption says *"11 Hoyt in
Brooklyn"*, the post is about *"dense Downtown Brooklyn"*, and both pins within 400 m use
`Brooklyn`. **One line to change.**

---

## ✅ The hero audit — 13 opened, zero wrong subjects

**Every one was opened and read against its caption.** Several name themselves: `Studio Gang /
Populus` ×2, `Arkansas Museum of Fine Arts`, `ARKANSAS ARTS CENTER`.

🔴 **But four are not photographs of a finished building, and that is the batch's real
weakness.** These are an architecture practice's own marketing posts, so the frames skew to
drawings, diagrams and covers rather than street photography:

| # | Pin | What the hero actually is |
|---|---|---|
| 5 | **Building the Arkansas Museum of Fine Arts** | a **crayon-textured plan diagram** — orange blocks and a white "blossoming" addition. **No building in frame at all.** The weakest in the batch. |
| 11 | Solar Carve | an **axonometric drawing**, exactly as its own caption says (*"this axonometric illustration by @rodrigodamati"*) |
| 12 | Solar Carve from the High Line | the **High Line path** — the building is not identifiable |
| 10 | One Hundred | a **construction aerial**, crane still up; honest to a caption that says *"tops out today"* |
| 2 | Spelman | a **magazine cover** (gb&d masthead + cover lines). The picture inside it is genuinely the atrium. |

**Flagged, not fixed.** A link pin re-hosts only the thumbnail, so no other frame exists — the
choice is keep or pull, and that is the owner's. Precedents run both ways: Mercedes-Benz
Stadium was pulled; the Koons/LACMA and Hugo de Grootplein ones were kept.

---

## ⚠️ Two hand re-crops — the vertical `--focus` gap, EIGHTEENTH batch running

`render_hero` crops at `centering=(focus, 0.5)` — **the vertical is hardcoded**, so `--focus`
cannot recover text sliced off the top of a 9:16 frame.

- **Populus** — the centred square cut `Studio Gang / Populus` through the letters. Re-rendered
  at **vfocus 0.20**, recovering it whole.
- **Transforming the Arkansas Arts Center** — a 16:9 source, so the square is *height*-limited
  and the centred crop gave `AS ARTS CENTER` + `LITTLE ROCK, A`, both broken. Re-rendered at
  **hfocus 0.00**, recovering **`ARKANSAS ARTS CENTER`** whole. ⚠️ **Stated trade-off:** the
  text spans nearly the full width so no square can hold both halves (the Depot MVRDV case);
  this buys the subject's name at the cost of `LITTLE ROCK, ARKANSAS` and pushes the museum
  complex toward the right edge.

Both re-rendered through a **mirror of the tool's own pipeline** — importing its `trim_bars`
and constants so the two cannot drift, same blur/dim/quality, **same filenames**, so
`Tours.json` is untouched.

⚠️ **Straplines elsewhere were deliberately left.** Recovering what the crop destroyed is not
the same as removing what the creator put there.

---

## Tagging

**Every one of the 13 captions names Studio Gang or Jeanne Gang as the designer**, so all 13
carry **`Jeanne Gang`** — the documented practice→person mapping; `Studio Gang` is deliberately
absent from the vocabulary — **alongside `Designed by a Master`**, never replacing it.
`Tag.matches` performs no implication and the curated home shelf is keyed on that literal
string.

⚠️ **The Gilder Center pin's tag set matches the two existing Gilder pins exactly**
(`Museum, Architecture, Contemporary, Jeanne Gang, Designed by a Master`), so the trio shares
shelves — the documented rule where one subject exists as several entries.

⚠️ **Collaborators are absent from the vocabulary and ship untagged**, deliberately: **SCAPE /
Kate Orff** (AMFA and 11 Hoyt landscape), **Michaelis Boyd** (11 Hoyt interiors), **Hollander
Design**, **Polk Stanley Wilcox**. Adding them is a `Models/Tag.swift` **code** change, kept
out of a content batch.

---

## Verification

- **Validator mirror self-tested 24/24 with a clean control**, then **0 errors, 0 warnings
  across 1,552 tours + 1,214 pins + 121 places** at 479 tags. **Exit code read directly, not
  through a pipe.**
- ⚠️ **20 faults injected against THIS batch's own 13 rows — 17 caught, control clean before
  and after.** The 3 misses are the documented mirror blind spots (**centroid drift, empty
  title, negative duration**) — 🔴 **and each was checked against `validate-tours.swift` before
  being called a blind spot**, because session 142 shipped a "blind spot" that was a rule it had
  invented. All three are real Swift rules (lines 458, 683, 616) and **all three were asserted
  directly on the 13 instead: 0, 0, 0**, alongside 17 more direct assertions — all 0.
- `make-link-pin.py --selftest` **71/71** ⚠️ **with Pillow installed first** (a bare container
  reports 62/62, which reads as a pass and is not one).
- **0** duplicate tour/stop/maker ids, **0** collisions with live ids, **0** already-pinned
  sourceURLs, **0** byte-duplicate heroes. **13 files for 13 pins**, URL set == file set.
- **0 filename collisions** against **7,062** gh-pages `images/` paths, the listing **asserted
  to hold >1,000 first**. ⚠️ The bare-slug check was **clean too**, so the handle suffix was not
  load-bearing this batch.
- `Tours.json` **byte-stable under a Python re-dump before AND after editing**; diff **640
  insertions / 0 deletions**, asserted purely additive — `tours` and `places` byte-identical,
  existing makers and pins unchanged as prefixes, top-level keys unchanged.
- `seed_from_toursjson.py` clean at **331 / 2,766 / 3,138 / 121**; **0 `images//`** in the
  catalogue *or* the generated SQL.
- gh-pages `d22dca3`: remote head **re-read in the same command as the push**, push status read
  through **`PIPESTATUS`**, tree diff **exactly 13 additions, 0 deletions, nothing outside
  `images/`**. The deploy read **`in_progress`, never `cancelled`** against the Actions API and
  served 404 for several minutes, after which **all 13 live URLs were hash-verified against the
  uploaded bytes — 13 ok, 0 mismatch, 0 non-200.**
- 🔴 **`check-image-duplicates.py --pins` was run AFTER the deploy** (the session-135 false-pass
  lesson): **`OK — no suspicious duplicates`** over **1,209 images** (1,209 for 1,214 pins is
  the documented `@malata.antwerp` five-pins-one-URL case), shared-URL half **0 errors / 208
  documented reuses** — identical to the recorded baseline, so this batch adds no shared URL.
- ⚠️ **Nothing compiled locally** — no Swift toolchain in a Linux web session. **No PR is open,
  so CI has not run.**

---

## ⚠️ A parallel session is in flight

While this batch was being built, another session pushed **41 `@itshistoryonair` link-pin
heroes plus a creator avatar** to gh-pages (`94264b6c`, the commit this batch's tree was built
on). **Their catalogue change has NOT merged** — `main` was still `89bb15c8` at the end of this
session — so **expect a `Tours.json` conflict when it does**: both sides append to `linkPins`
and `makers`.

**Resolve it the documented way** — take `main`'s file and re-run the idempotent assembler
(`scratchpad/sg/assemble.py`), never hand-resolve a JSON conflict — and re-check overlap on
sourceURL, ids and hero filenames afterwards.

---

## Open for the owner

1. **AMFA is four markers deep** — past `TourSetMap.maxStacked`. Make it a place, or drop one
   of the four?
2. **The Gilder Center is three deep with no headroom** — same question, and it would fold in
   two pins that are already live.
3. **The four non-photograph heroes** — keep or pull? The AMFA plan diagram is the one that
   renders as an abstract graphic on the map.
4. **11 Hoyt's `city`** — `Brooklyn` as shipped, or `New York` to match the dominant convention?
