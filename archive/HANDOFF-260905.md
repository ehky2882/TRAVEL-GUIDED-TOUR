# HANDOFF 2026-09-05 (session 144) — forty-one @itshistoryonair link pins

Branch `claude/new-tour-links-lze4ab`. Content only — no Swift, no SQL, no build. Opened as
[#737](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/737) on owner instruction (*"Open pr and
merge when ready"*) — content-only, so the auto-merge class: squash on green CI, no approval gate.

**Catalogue on the merged base: `linkPins` 1,201 → 1,242 · `makers` 328 → 329 · `tours` and
`places` byte-identical at 1,552 and 121.** Diff **1,897 insertions / 0 deletions**.

---

## What arrived

The owner pasted **46 rows** — a `vm.tiktok.com` share link followed by a **Plus Code + locality**
line. Every one resolves to **TikTok `@itshistoryonair`**, a history-explainer account: one
creator, one new maker row (`1FAE9AD9-F1B7-5A99-A4B9-2FC221902788` =
uuid5 `atlas-maker:tiktok:@itshistoryonair`).

**46 links → 41 distinct posts → 41 shipped.** Five links were pasted twice
(`ZGdQdgp4h` three times, `ZGdQdK2SE` twice, `ZGdQRqNoU` twice), which `normalize_url`
canonicalises identically. **0 already pinned, 0 dead posts, 0 `/photo/` carousels.**

**Cyprus and Bolivia are the catalogue's 46th and 47th countries.** 14 new cities: Alang,
Amesbury, Boulder City, Curon Venosta, Dry Tortugas, Herne Bay, Marathon, Nicosia, Niles, Rapa,
Toruń, Uyuni, Warsaw, Łapalice.

---

## 🔴 The headline: six sites sit EXACTLY at the stack cap, and they are all one creator

`check-place-candidates.py` goes **12 EXACT → 21** and **53 NEAR → 63**. Every added group is a
site the owner sent more than one link for; **nothing was nudged together to manufacture a group
and nothing nudged apart to dodge the checker** — the report diff proves it removes nothing.

**`TourSetMap.maxStacked = 3`**, and **all 41 pins are the same creator**, so these stack on
`@itshistoryonair`'s own maker page. The nine new EXACT groups:

| site | coincident pins | also within 6 m | at the cap? |
|---|---:|---|---|
| **Alcatraz** | **3** | Atlas SFO `Alcatraz` tour, **5.7 m** | **yes, no headroom** |
| **Hoover Dam** | **3** | — | **yes, no headroom** |
| **Fort Jefferson** | **3** | — | **yes, no headroom** |
| **Leaning Tower of Niles** | **3** | — | **yes, no headroom** |
| Paris Catacombs | 2 | Atlas PAR `Catacombs of Paris`, **5.7 m** | one spare |
| Washington Monument | 2 | — | one spare |
| Ellis Island | 2 | — | one spare |
| Seven Mile Bridge | 2 | — | one spare |
| Alang | 2 | — | one spare |

⚠️ **A CORRECTION TO WHAT THIS SESSION FIRST BELIEVED: Alcatraz is *at* the cap, not past it.**
An early read called it "4 markers, past the cap of 3". Measured: the three new pins are exactly
coincident, and the Atlas SFO tour is **5.7 m away** — a *separate* marker, not part of the stack,
because the Plus Code decodes to a cell centre at 7 decimals while the tour stores 4 (the
documented CalAcademy rounding artifact). **Nothing in the catalogue is unreachable today.** What
is true is that a fourth link at any of the four three-deep sites would put one marker permanently
out of reach, invisibly. **That is the owner's call and nothing was created here** — a place needs
its own copy, address, photograph and approval.

⚠️ **Eastern State is a different shape and the checker cannot see it.** The new pin sits **1.8 m**
from the point and **3.7 m** from the existing two-member `Eastern State Penitentiary` place, so it
is **not coincident** and never appears in EXACT — it shows only as a 4 m NEAR pair. Joining it
would be a deliberate move of a `manual` pin onto the place's coordinate (the Guggenheim / ROM
Crystal precedent), which is one line.

---

## Coordinates

All 41 decoded with `scripts/decode-plus-code.py`, **which self-tests on every invocation** (3
published anchors + the floor-not-round encode + a refusal to guess grid digits + 2,000
round-trips + 18 short-code recoveries across four hemispheres). Short codes were recovered
against **structured** city geocodes (`city=`/`country=`), which avoids the province-centroid trap.
Every point was then **reverse-verified at zoom 18**.

**🔴 RE-QUERYING WAS THE WHOLE FIX TWICE, AND BOTH TIMES THE FIRST ANSWER LOOKED LIKE A REFUTATION.**

- **Crystal Palace Subway** reverse-geocoded to an **unnamed pedestrian way** — no name, no
  address, the shape of a point that has landed on nothing. A *forward* query for the subject's own
  name returns `Crystal Palace Subway` at **11 m**. The coordinate was right the whole time.
- **No Man's Land Fort** returned **ZERO HITS** unbounded. Dropping the apostrophe and bounding to
  a Solent viewbox returns it **named exactly, 45 m** away. A first-pass miss is not evidence a
  place is unmapped.

**⚠️ Three subjects are in no OSM record under their own name, and the REVERSE geocode is what
named them** — the opposite of the usual direction: `Museo Abierto del Ferrocarril` for Bolivia's
train graveyard at Uyuni, `Officers' Quarters` inside Fort Jefferson, and **`Comiskey Park Home
Plate`** for the White Sox pins, which is a marker on the old ballpark's site and is exactly what
those two posts are about.

**⚠️ THE WEAKEST COORDINATE IN THE BATCH, STATED RATHER THAN HIDDEN: `The Sea Forts at War`.** The
owner's full Plus Code lands **in open water, 2,657 m from Shivering Sands Fort**, and reverse-
geocodes to "Rochester Riverside" — 40 km away, because there is no addressed feature at sea. **The
owner's coordinate was KEPT**: the caption says *"forts"* plural and the point sits inside the
Maunsell field, so a fort-specific coordinate would assert more than the post does. Ships
`city: "Herne Bay"`, the nearest mainland town, and both the city and the point are approximate.

---

## Heroes

**All 41 opened and read against their captions — zero wrong subjects.** 42 files uploaded
(41 heroes + the creator avatar); **42 uploaded = 42 referenced, 0 orphaned, 0 missing**, and
**41 distinct heroes for 41 pins** — the check that catches two pins slugging identically.

**⚠️ FIVE WEAK HEROES, FLAGGED NOT FIXED.** A link pin re-hosts only the thumbnail, so no other
frame exists — the choice is only ever keep or pull.

- **🔴 `Why the Cliff House Was Built` is the worst hero shipped in some time: a completely blurred,
  unreadable smear.** Not a crop artifact — the source thumbnail itself is out of focus. The
  likeliest pull in the batch.
- **`George Washington's Legacy`** is a **portrait painting of Washington**, not a photograph of
  the Washington Monument the pin sits on.
- **`The Pyramid of Rapa`** is a dark, low-contrast interior of the mausoleum.
- **`The Most Valuable Ships at Alang`** is a generic wrecked hull that could be any shipbreaking
  yard.
- **`What's Inside the Paris Catacombs`** is a historical print rather than a photograph.

⚠️ **`The Oldest Photograph of Stonehenge` is ALSO a historical photograph and that one is
CORRECT** — the post's entire subject *is* the earliest known photograph of the stones. Do not
"fix" it by sourcing a modern frame.

**⚠️ Four hand re-crops — the vertical `--focus` gap, EIGHTEENTH batch running.** Every source is
9:16, so the square crop is width-limited and **`--focus` does nothing vertically**. Re-rendered
through a mirror of the tool's own pipeline (`recrop.py` imports `make-link-pin`'s own `trim_bars`,
same blur/dim/quality, **same filenames**, so `Tours.json` is untouched), and the mirror
**self-checked against `render_hero` at focus 0.5 before being trusted**. Each re-crop recovers the
subject's own burned-in *name*; **straplines clipped elsewhere were deliberately LEFT** — a hook is
not the subject's name (the California Academy rule).

**🔴 THREE SUBJECTS ARE COVERED BY LIVE ATLAS TOURS WHOSE HEROES SIT AT THE BARE VENUE SLUG** —
`alcatraz_hero.webp`, `eiffel-tower_hero.webp` and `marina-city_hero.webp` are all on gh-pages
right now. Subject-specific slugs plus the handle suffix gave **0 collisions against 7,020
existing `images/` paths**; a bare venue slug would have written over three real tours'
photographs, which since #567 a downloaded tour would never see corrected.

---

## Editorial

**⚠️ ONE CAPTION IS FACTUALLY WRONG AND STAYS THE CREATOR'S.** The No Man's Land Fort post says the
Solent forts were built to *"defend the United States"* — they are Palmerston forts built against a
feared French invasion of Portsmouth. The caption is kept **verbatim** in `longDescription`, and
**nothing this catalogue authors repeats it** (the Schweizer convention).

**⚠️ NO ARCHITECT TAG ANYWHERE IN THE BATCH.** Not one caption names an architect — these are
history explainers, not architecture posts — so the Jules Dalou rule leaves all 41 clean. ⚠️ **That
includes the Palace of Culture and Science, Łapalice Castle, Marina City and the Leaning Tower of
Niles**, all of which have well-known authorship a general-knowledge sweep would happily supply.
**Do not "finish the job."**

⚠️ **`YouTube @ITSHISTORY` already exists** in the catalogue (1 pin, Habitat 67) and is plausibly
the same creator on another platform. The new `TikTok @itshistoryonair` row is **separate by
design** — the uuid5 scheme keys on `<platform>:@handle`, the same way wienerberger and Avant Arte
each hold two rows.

---

## `main` moved mid-session, and the edit was redone the documented way

**[#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734) merged** while this batch was
being validated — 33 Toronto/Mississauga pins, 6 places and 2 architects, taking the base from
1,168 → 1,201 pins, 305 → 328 makers, 115 → 121 places and the vocabulary 477 → 479.

The catalogue edit was **redone the documented way: reset onto `main` and re-run the idempotent
assembler, never hand-resolve a JSON conflict.** The branch carried no commits, so the reset was
clean. **Overlap with Toronto re-verified at 0 on every axis** — sourceURLs, tour ids, stop ids,
maker id and hero filenames — and every check below was re-run on the merged base. The diff came
out **unchanged at 1,897 / 0**.

---

## Verification

- **Validator mirror self-tested 24/24 with a clean control**, then **0 errors, 0 warnings across
  1,552 tours + 1,242 pins + 121 places** at **479 tags**. ⚠️ **Exit code read directly, never
  through a pipe** (the session-90 `PIPESTATUS` trap).
- **⚠️ 22 faults injected against THIS batch's own 41 pins — 22/22 caught, control clean before and
  after.** The harness **counts errors AND warnings** (the session-141 bug: "no Place type" and "no
  Theme" are *warnings*, and counting only errors reports false misses), injects **in memory via
  the mirror's own `check()`** rather than onto disk (the mirror draws its control from the live
  catalogue and exits 2 rather than reporting when that file is dirty), and reads `check()`'s
  **`(errors, warnings)` tuple** rather than mistaking it for an exit code (the session-142 false
  pass). ⚠️ **The new-pin ids are DERIVED FROM THE DIFF against `HEAD`**, not read from a scratch
  file, so they are exactly what the working tree adds.
- `make-link-pin.py --selftest` **71/71** ⚠️ **with Pillow installed first** — a bare container
  reports 62/62, which reads as a pass and is not one. `decode-plus-code.py` self-tests on every
  invocation, clean.
- **0** duplicate tour or stop ids, **0** collisions with live ids, **0** already-pinned
  sourceURLs, **0** in-batch duplicate sourceURLs, **0** byte-duplicate heroes. Closest perceptual
  pair **hamming 32 / pixdiff 57.0** (identical pictures score under 1); 3 pairs nominated at
  hamming ≤ 45, all rejected by the thumbnail stage.
- `Tours.json` **byte-stable under a Python re-dump before AND after editing**, on both bases; diff
  **1,897 insertions / 0 deletions**, asserted purely additive with `tours` and `places`
  byte-identical and the 1,201 existing pins unchanged as a prefix.
- `seed_from_toursjson.py` clean at **329 / 2,794 / 3,166 / 121**; **0 `images//`** in the
  catalogue *or* the generated SQL.
- gh-pages **`94264b6c`**: remote head **re-read in the same command as the push**, push status
  read through **`PIPESTATUS`**, tree diff **exactly 42 additions, 0 deletions, nothing outside
  `images/`** (7,020 → 7,062 paths) — **re-verified against the remote afterwards**, with the
  commit confirmed **still gh-pages head**. The deploy read **`in_progress`, never `cancelled`**
  against the Actions API (run 836), after which **all 42 live URLs were hash-verified against the
  uploaded bytes — 42 ok, 0 mismatch, 0 non-200**.
- 🔴 **`check-image-duplicates.py --pins` was run AFTER the deploy** (the session-135 false-pass
  lesson): **`OK — no suspicious duplicates`** over **1,237 images** (1,237 for 1,242 pins is the
  documented `@malata.antwerp` five-pins-one-URL case), shared-URL half **0 errors / 208 documented
  reuses** — identical to the recorded baseline, so this batch adds no shared URL.
- ⚠️ **Nothing compiled locally** — no Swift toolchain in a Linux web session, so **CI on a PR
  would be the only compile check**, and no PR is open.

---

## Owed

1. **The places decision (owner).** Four sites are three deep at the cap — **Alcatraz, Hoover Dam,
   Fort Jefferson, the Leaning Tower of Niles** — and a fifth, **Eastern State**, could join the
   place that already exists as a third member. Recommendation: **make places for the four**, since
   all four are one creator and therefore stack on that creator's own page with no headroom.
2. **The Cliff House hero** — the blurred one. Keep or pull is the owner's call.
3. **No PR is open**, so nothing has compiled and nothing is live.
