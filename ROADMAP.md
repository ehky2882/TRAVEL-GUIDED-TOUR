# Atlas — V1 Roadmap

> **How to read this file:** every technical term has a plain-English
> analogy in parentheses so a non-coder owner can follow along. This is a
> **living document** — milestones, scope, and priorities will shift as
> we build. Edit freely.

> **May 2026 pivot note.** This roadmap was reset after the product
> pivoted from "editorial city guide" to "creator platform for audio
> tours." See `atlas_claude_code_prompt.md` for the spec. The earlier
> editorial-reader milestones (M4–M11 in the previous draft) are gone
> because the product shape that needed them is gone. The previous
> roadmap survives in git history if anyone needs to look back.

---

## Owner direction (May 2026)

Principles that override everything else in this file:

1. **Functionality first; design and tone deferred.** Don't burn
   cycles on color palettes, typography, app icons, custom map pins,
   or final editorial tone. Get the audio-tour experience working end
   to end, then polish.
2. **Build so the deferred design pass is cheap.** All new code uses
   `Theme/Atlas{Colors,Typography,Spacing}.swift` tokens even though
   their values are placeholders. The future design decision should be
   a 3-file change, not a 60-file rewrite.
3. **V1 is consumer-side only, backend-free.** Per the spec, payments,
   accounts, and in-app maker upload are post-V1. The V1 UI is built
   in the *shape* of the eventual creator platform so nothing the
   consumer sees needs to be redesigned later.
4. **Review workflow.** Owner reviews via iOS Simulator or TestFlight,
   not by reading code. Each milestone ends in a runnable, reviewable
   state.

---

## Where we are right now


<!-- Older Status blocks live in archive/ROADMAP-STATUS-HISTORY.md -->

🔴 **The 113 older Status blocks are in
[`archive/ROADMAP-STATUS-HISTORY.md`](archive/ROADMAP-STATUS-HISTORY.md)**,
verbatim. Nothing was deleted. They had grown to **366,342 of this file's
427,655 bytes — 86%** — one paragraph appended per session, never pruned, in a
section whose whole job is to say where things are *now*.

⚠️ **Search that archive, never load it whole:**

```bash
grep -n "session 14" archive/ROADMAP-STATUS-HISTORY.md
grep -n "^\*\*Status (2026-08" archive/ROADMAP-STATUS-HISTORY.md
```

🔴 **Do not report live state from this section — it is a log, not a status.**
The newest block below is only as current as the last session that wrote one.
Run `bash scripts/session-start.sh` for what is actually true right now.

**The 6 most recent blocks:**

**Status (2026-09-07, session 148, [PR #751](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/751), squash `783f1822` — MERGED):** web session (**content**) — **thirty-seven link pins from three creators, and one post that is three pins.** 37 owner-sent Instagram links → **35 distinct shortcodes** → **37 pins**; `@rayisaplace` 32 · `@sarah_hsiao` 4 · `@itsblankcreative` 1. **linkPins 1,306 → 1,343 · makers 350 → 353 · `tours` and `places` byte-identical**; diff **1,733 insertions / 0 deletions**. ⚠️ **The heading was wrong for the sixth batch running — "Itsblankcanvas" is `@itsblankcreative`**; read the payload, not the heading. 🔴 **ONE POST IS THREE PINS — the `@malata.antwerp` shape, only the SECOND instance ever.** `DWHSGzlEZSv` is one post about **Peter Zumthor** naming four of his works, and the owner supplied **three different Plus Codes for it** (Los Angeles / Vals / Mechernich). The fragment id scheme (`atlas-tour:link:<url>#<fragment>`, same on `atlas-stop:`) is written down nowhere and was **reverse-engineered from the live catalogue again**, verified by reproducing **4 of the 5 live malata pins field-for-field on BOTH ids** before minting. The three **share ONE hero**, so **35 files cover 37 pins** and a naive `len(files) == len(pins)` assertion fails; the file is named `peter-zumthor-…` rather than a LACMA-specific stem. ⚠️ **The cost is stated:** someone at Therme Vals or the Bruder Klaus chapel gets a pin whose photograph is LACMA (the Charging Bull trade-off); one line removes any of the three. 🔴 **TWO REFERENCE GEOCODES WERE WRONG AND BOTH WERE CAUGHT BEFORE USE** — a short Plus Code recovers against a reference point, so a wrong reference moves the pin to another country silently and precisely: `Chuo City Tokyo` matched **a confectionery in Chuo-ku OSAKA**, `Venice Italy` matched **a restaurant in GRAZ, AUSTRIA**. **Use the structured Nominatim parameters for a short-code reference, never free text.** ✅ **Re-querying was the whole fix twice more** — the San Francisco Ballet Building and the Edith Farnsworth House both returned **zero hits** first pass and were then named exactly. **Coordinates:** Unimocc **moved 152 m** onto OSM's named node; Art Aquarium (70.8 m) and InterContinental Khao Yai (48.3 m) **kept**; **Seronera verified arithmetically** (the recovered point re-encodes to `6G9PHMMP+G7`, matching the owner's code character-for-character) and shipped **flagged approximate**. ⚠️ **`city: "Lausanne"` was checked and is correct** — the reverse says **Ecublens** but landed on a different EPFL feature, while a **forward** search returns OSM's `Rolex Learning Center` **at 53.5 m carrying `city: Lausanne`**; ⚠️ the owner supplied **no locality** there, so it began as an inference and was verified. **All 37 cities swept against their reverse geocodes**, eight disagreements all read by hand and all correct. 🔴 **A pre-existing defect found, flagged, NOT fixed** — the Atlas São Paulo `Casa de Vidro` tour sits **841.8 m** from this batch's pin while OSM's `Instituto Bardi` is **13.4 m from the pin and 833 m from the tour**; that tour is **`geofenced`**, so moving it changes where its audio fires — **owner's call.** **Ten same-subject pairs**, all retitled and all measured: **max depth 2** against `TourSetMap.maxStacked = 3`, nothing at or over the cap; ⚠️ the Calder Gardens pair is **3 cm** apart and still reports NEAR, not EXACT (the CalAcademy artifact). Ten place candidates flagged, none created. 🔴 **A real blind spot found in `validate-tours-mirror.py` and closed** — the harness reported *"title on stop empty"* MISSED, and it was **read out of the Swift rather than recalled** (sessions 142, 143 and 145 each shipped an invented rule): **line 458 checks the entry title, line 591 checks the STOP title separately**, and only the entry one was mirrored. Closed and **pinned in the mirror's own selftest, 30/30 → 31/31**. ✅ **All 35 heroes opened and read against their captions — zero wrong subjects**, several naming themselves in frame (**`CHOSES LÉGÈRES`** stencilled on Villa E-1027's wall — Eileen Gray's own lettering). ⚠️ **Five weak heroes flagged not fixed**, `Gae Aulenti at the Musée d'Orsay` the weakest (a B&W archive interior of Olivetti typewriters — **not the museum and not the architect the pin names**). ⚠️ **No hand re-crop was needed, and one candidate was REJECTED after looking at it** — `The Stahl House` clips to just "WHAT", but the subject's name is nowhere in the frame, so nothing could be recovered. ⚠️ **A false alarm I raised on myself:** an ad-hoc check reported *"architect tags used: []"* because its regex **returned an EMPTY vocabulary**, so nothing could match — the session-137 empty-parse class, which the mirror guards against and the ad-hoc check did not. **Assert the parse is non-empty before believing its verdict.** The tags were all correct: **14 architect names in use**, each alongside `Designed by a Master`. ⚠️ **Four deliberate omissions (the Sullivan rule):** `Philip Johnson` NOT tagged on the Rothko Chapel — **Rothko rejected his design and he left**; `Frank Lloyd Wright` NOT on Nakashima's compound (*"a disciple of"*); `Antoni Gaudí` NOT on the Tarot Garden or Sant Pau. ⚠️ **Eighteen named architects are absent from the vocabulary**, `Eileen Gray` and `Julia Morgan` the most conspicuous — a `Models/Tag.swift` **code** change kept out of a content batch. 🎉 **Tanzania is the catalogue's 59th country**; **404 cities**, fifteen of them new, re-derived over `tours` **and** `linkPins` together. **Verification:** mirror **31/31 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,343 pins + 130 places**, exit code read directly; fault harness **24/24, control clean both sides**; **0** duplicate ids, collisions with live ids, already-pinned sourceURLs or byte-duplicate heroes; **0 filename collisions against 7,126 gh-pages `images/` paths**, the listing asserted >1,000 first; **35 files = 35 referenced, 0 orphaned**; `Tours.json` **byte-stable before AND after editing** on both bases; seed clean at **353 / 2,895 / 3,267 / 130** with **0 `images//`**; `check-place-candidates.py` **EXACT unchanged at 22 / NEAR 61 → 70**, the report diff **removing nothing**; **743 entries name an architect and 0 are missing the shelf tag**. ⚠️ **`main` moved mid-session** — [#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743) touches `Tours.json`, so the branch was **reset onto `main` and the assembler re-run on its file, never hand-resolved**, overlap re-verified at 0 on every axis and every check re-run; the diff came out **unchanged at 1,733 / 0**. ⚠️ **The Pages deploy was CANCELLED** by a parallel session's push of 54 more heroes — harmless, and **proved so the documented way**: my commit re-confirmed **an ancestor of head**, all 35 paths in the head tree, **all 35 blobs byte-identical**. Detail: `archive/HANDOFF-260907-4.md`. Earlier status follows.
**Status (2026-09-07, session 147, branch `claude/tour-links-6l4xq1`):** web session (**content**) — **twenty-eight link pins across fourteen countries, eleven of them new to the catalogue.** 29 owner-sent lines under three loose headings → **28 distinct posts** (one TikTok pasted twice) → **28 shipped, 0 blocked, 0 already pinned**. **linkPins 1,278 → 1,306 · makers 346 → 350 · `tours` and `places` byte-identical.** 🎉 **ELEVEN NEW COUNTRIES — the largest expansion any batch has produced, against a previous record of three**: Turkmenistan · Madagascar · Yemen · Peru · Jordan · Uzbekistan · Turkey · Afghanistan · Singapore · Tunisia · Mongolia, taking the catalogue **47 → 58 countries and 367 → 389 cities** (re-derived over `tours` **and** `linkPins` together). Five creators, **four new maker rows** — `TikTok @itshistoryonair` already existed and the uuid5 scheme reproduced its id field-for-field, so those 7 pins merged rather than duplicating. ⚠️ **The heading was loose for the fifth batch running and the payload named a fifth creator** (`@travpholer`, inside the "Iamlamlam" block) — **read the payload, not the heading.** 🔴 **One coordinate was in open water and moved 69 km** — the Uros floating-islands pin reverse-geocoded to a bare `Perú` at zoom 12 **and** 14, no name and no address, the signature of a point that has landed on nothing; moved onto `Islas Flotantes de los Uros`, which reverse-verifies by name. 🔴 **TWO COORDINATES LOOKED WRONG AND WERE RIGHT, and I nearly moved both** — I had the baobabs 4.8 km off against `Allée des Baobabs`, but a **bounded** search returns **`Baobabs Amoureux` at 26 m**, exactly what the caption names (*"Beloved Baobab / 兩棵樹相依而生"*): **distance from the OBVIOUS landmark proves nothing when the caption names a different one**; and OSM's `Skylodge Adventure Suites` sits **14 km** from the Starlodge point while the caption says outright they are separate properties. A third was **relabelled rather than moved** (the `Kakslauttanen` code lands on the **Aurora Queen Resort**, ~20 km away in the same municipality). ⚠️ **The softest coordinate is stated, not hidden** — the Awaji post arrived with no code at all, so the pin sits on the named quarter **松帆志知川** that contains its published address (the enclosing-feature case). 🔴 **Three stack-cap findings, flagged and NOT acted on** — `check-place-candidates.py` goes **19 EXACT → 22** and **59 NEAR → 62** with the report diff proving it **removes nothing**; all three are one subject sent twice, and **Griffith Observatory is the one that bites**: the existing place (2 members, one capsule) plus two new coincident pins make **3 markers against `TourSetMap.maxStacked = 3` with no headroom**. ⚠️ **Measured, not assumed** — the new pins sit **5.4 m** from the place (the CalAcademy rounding artifact), so they are not members; **joining both is one line each and takes the place 2 → 4 members.** 🔴 **Nothing was nudged onto a place coordinate** — that manufactures an EXACT group with no place behind it. ✅ **All 28 heroes opened and read against their captions — zero wrong subjects**; **four hand re-crops** through a mirror **self-checked against `render_hero` at vfocus 0.5 first (28 identical, 0 mismatched)**. 🔴 **Three real blind spots found in `validate-tours-mirror.py` and closed — and a fourth that was a rule I INVENTED.** 24 faults injected against this batch's own 28 pins, first run **20/24**; reading `validate-tours.swift` rather than recalling it (sessions 142, 143 and 145 each shipped an invented rule) found three genuine gaps — **an empty title** (line 458), **a link pin with a nonzero `totalDurationSeconds`** (line 565, checked against **0 exactly**) and **centroid drift** (lines 683-685) — while the fourth, `city: ""`, **is not a rule at all**: the Swift declares `let city: String?` with no non-empty check anywhere. Real score **20 of 23**. ⚠️ **The centroid rule is a WARNING**, so closing it needed `warns=True` in the mirror's own selftest (the session-141 bug): **27/27 → 30/30**, and the batch re-run then went **24/24 with a clean control both sides**. **Verification:** mirror **0 errors, 0 warnings across 1,552 tours + 1,306 pins + 130 places** at 479 tags, exit code read directly; **0** duplicate ids, collisions with live ids, already-pinned sourceURLs or byte-duplicate heroes; **28 distinct heroes for 28 pins**; **0 filename collisions against 7,098 gh-pages `images/` paths**, the listing asserted to hold >1,000 first; `Tours.json` **byte-stable before AND after editing** on both bases, diff **1,301 insertions / 0 deletions**, asserted purely additive; seed clean at **350 / 2,858 / 3,230 / 130** with **0 `images//`** in the catalogue *or* the SQL; gh-pages `21d82cd` tree diff **exactly 28 additions, 0 deletions, nothing outside `images/`**, deploy read **`in_progress`, never `cancelled`** and finished `success`, after which **all 28 live URLs were hash-verified against the uploaded bytes — 28 ok, 0 mismatch, 0 non-200**; 🔴 **`check-image-duplicates.py --pins` was run AFTER the deploy** (the session-135 false-pass lesson): **`OK — no suspicious duplicates`** over **1,301 images** (1,301 for 1,306 pins is the documented `@malata.antwerp` five-pins-one-URL case), shared-URL half **0 errors / 208 documented reuses** — identical to the recorded baseline. ⚠️ **`main` moved TWICE mid-session** — [#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742) landed the catalog materialisation (no `Tours.json` change, so the branch fast-forwarded), then [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) merged **while this PR's own CI was green and running**, making the Gilder Center a place (places 129 → 130) and moving two pins, so `Tours.json` genuinely conflicted. Resolved the documented way — **main's file taken wholesale and the idempotent assembler re-run on it, never hand-resolved** — with **overlap re-verified at 0 on every axis** and every check re-run on the merged base (checker **19 EXACT → 22 / 59 NEAR → 62**, the same +3/+3 delta, still removing nothing). ⚠️ **#744 also claimed `archive/HANDOFF-260907.md`**, so this handoff is **`-2`**, and **both sides had edited the Key-facts counts** — merged into one line rather than left duplicated. ✅ **A content merge needs nothing extra under the new scheme, verified rather than assumed** — the regenerated seed SQL calls `refresh_catalog_snapshot()` as its last act. 🔴 **AND AFTER THE MERGE THAT COMFORT PROVED MISPLACED — the guard cuts both ways.** `backend/catalog_snapshot.sql` is an **owner paste** and has not been run, so `to_regprocedure(...)` is null, the seed **skips** the refresh, raises a notice and still finishes green. Probed live rather than inferred: `catalog_snapshot_age()` and `get_catalog_built()` both **404 `PGRST202`**, and the RPC still failed **2 of 5 spaced calls** with **`500 / 57014 statement timeout`** — the very symptom #742 was written to fix. **A guarded no-op looks identical to a success from the outside; ask `catalog_snapshot_age()`, never a green seed job.** ✅ **SUPERSEDED THE SAME EVENING — the owner pasted it at 21:44 UTC and it is APPLIED; nothing is owed.** Re-probed before merging #746 rather than carried from this file: `catalog_snapshot_age()` **200 with a timestamp**, `check-catalog-keys.py`'s in-use line flipped, **`get_catalog()` 200 on 4 of 4** against 3 of 3 500s an hour earlier. ⚠️ **Fixed, not sub-second** — total 1.2–4.2 s, but **TTFB 1.7–3.7 s with the 10.6 MB body transferring in the remaining 0.3–0.5 s**, so the time is in the query and session 146's *"seconds means not served"* criterion is too crude alone; **split TTFB from total**. 🔴 **A probe is a measurement with a timestamp, not a durable fact — re-probe before landing a live-state claim.** **MERGED as squash `45914d1f`; verified against the LIVE systems** — the RPC serves `linkPins` **1,306** / `places` **130** with **0 pins wrongly inside `tours`**, the gh-pages mirror the same. Detail: `archive/HANDOFF-260907-2.md`. Earlier status follows.
**Status (2026-09-07, session 147, branch `claude/gilder-center-place`):** web session (**content**) — **the Gilder Center becomes a place, and a bug the mirror cannot see.** Owner: *"MAKE GILDER CENTER A PLACE. DONT WORRY ABOUT WEAK HEROES."* **Places 129 → 130** — the last stack-cap finding the Studio Gang batch raised, closed. `tours` and `makers` **byte-identical**, the 129 existing places unchanged as a prefix, **exactly 2 link pins moved in exactly their four coordinate fields each**; diff **24 insertions / 8 deletions**, every deletion a coordinate line. 🔴 **The checker under-reported the cap, which is why this sat unbuilt** — three markers **at most 3.44 cm apart**, exactly at `TourSetMap.maxStacked = 3` with **no headroom**, but reported as an **EXACT pair plus a separate NEAR pair** because the third pin differs in the **7th decimal** (the CalAcademy rounding artifact); resolving it therefore moves two tiers, **EXACT 20 → 19 and NEAR 60 → 59**, with the report diff proving it **adds nothing**. All three members are link pins by **different creators**, so the cap bit the Home map and every place and list map rather than a creator page. 🔴 **A bug I introduced and caught by reading the diff, not the validator** — the assembler's first run wrote **`centerLatitude` / `centerLongitude`**, fields that **do not exist on `Tour`**, leaving the real centroid fields stale; **`validate-tours-mirror.py` passed it at 0 errors** because centroid-vs-stop agreement is a documented mirror blind spot that **`validate-tours.swift` does check**, so it would very likely have failed CI. The assembler now asserts **no member gains or loses a top-level key** and **every centroid mirrors its stop**, and the property is **asserted directly** (0 drift on the members, 0 catalogue-wide across **2,758** single-stop entries — ⚠️ 2,830 is the TOTAL entry count; the other 72 are walks, where a centroid legitimately differs from stop 0). ✅ **The anchor is OSM node `10172954431`** — forward geocode 0.0 m, reverse names the building — and all three markers had independently converged on it, so **one member did not move at all**; ⚠️ **`415 Columbus Avenue` was recollection** (unbounded, OSM returns hits 24 km, 85 km and 483 km away), and `200 Central Park West` is what OSM assigns to the whole campus at every probe. ⚠️ **Swept 400 m**: the **AMNH cluster at 176.1 m** is correctly excluded — ✅ **the owner ruled in session 140 that the Gilder Center stays separate**, and that is closed. ✅ **THE `@poche_space` PIN HAS SINCE MOVED HERE — owner instruction, same session** (*"OK move the poche space to the gilder center"*): it is substantively about the Gilder Center yet sat at the AMNH coordinate as one of that place's six members, and it was flagged rather than moved because it takes **AMNH 6 → 5** — a decision that shrinks a place another session built, so the owner's call, not a session's. **See the follow-up entry below.** ⚠️ **The hero is borrowed and structural** (borrowed count re-derived **54 of 130**); all three candidates rendered and looked at, ⚠️ **none of them an exterior**; ✅ **weak heroes CLOSED by the owner.** ⚠️ **The two members disagree on the opening date** — verified externally as **4 May 2023**, with February repeated nowhere (the Schweizer convention). **Verification:** mirror **27/27 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,278 pins + 130 places**; 🔴 **15 place-layer faults injected against THIS place — 14 caught, control clean both sides**, the one miss being the centroid blind spot deliberately included to confirm it is still blind; seed clean at **346 / 2,830 / 3,202 / 130** with **0 `images//`**; hero live **200**, hash-matched. ⚠️ **`main` moved mid-session** (#742) and **every check was re-run on the moved base** — it does not touch `Tours.json`, whose baseline is byte-identical on both sides. ✅ **MERGED as [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) (squash `f6c1815e`) on green CI, then verified against the LIVE systems rather than the merge's success line** — the Supabase RPC and the gh-pages mirror each serve **130 places** with all three members on the place coordinate, **0** members off their place coordinate catalogue-wide and **0** link pins wrongly inside `tours`. 🔴 **The RPC answered in 4.7 s, so [#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742)'s SQL is still unpasted — read the LATENCY, not the pass/fail count** ⚠️ **SUPERSEDED — the owner pasted it at 21:44 UTC the same evening and it is APPLIED; nothing owed.** Re-probed before merging: `catalog_snapshot_age()` **200**, `get_catalog()` **200 on 4 of 4** against 3 of 3 500s an hour earlier. ⚠️ **Fixed, not sub-second** — total 1.2–4.2 s but **TTFB 1.7–3.7 s with the 10.6 MB body in the remaining 0.3–0.5 s**, so the time is in the query and the *"seconds means not served"* criterion is too crude alone. 🔴 **A probe is a measurement with a timestamp, not a durable fact.**, corroborated by `check-catalog-keys.py` reporting *"catalog snapshot: not in use"*, and then **proved hard by probing the database directly: `catalog_snapshot_age()` and `get_catalog_built()` both return 404 `PGRST202` (they do not exist), and `get_catalog()` returned 500 on THREE of three spaced calls** — worse than the 4-in-12 session 146 measured. ⚠️ **The seed's `refresh_catalog_snapshot()` call is guarded by `to_regprocedure`, so with the SQL unpasted it silently skips and the seed still finishes green** — a guarded no-op is indistinguishable from a success; **ask `catalog_snapshot_age()`, never a green seed job.** ✅ **FOLLOW-UP, same session — the `@poche_space` pin moves onto the place (owner: *"OK move the poche space to the gilder center"*): Gilder 3 → 4 members, AMNH 6 → 5.** The pin is `manual` (asserted before anything was written; the builder refuses otherwise) and moved **176.3 m**; nothing else moved, diff **7 insertions / 7 deletions** — two `tourIds` arrays and the pin's four coordinate fields. ✅ **AMNH's hero is safe, checked not assumed** — a third photograph from the Atlas walk, which remains a member; borrowed count **still 54 of 130**. 🔴 **A real blind spot closed in `validate-tours-mirror.py`, found by injection and CHECKED AGAINST THE SWIFT FIRST** — `validate-tours.swift:553-554` errors when a `kind: "link"` stop is not `manual` and the mirror checked nowhere; added and pinned in its selftest (**30 → 31**), and the catalogue still reads 0 errors, proving no existing link pin is geofenced. ✅ **The centroid blind spot recorded above is now CLOSED by [#745](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/745)** — confirmed by injection, not by reading their PR body. ⚠️ **Flagged, not acted on: the moved pin carries no architect tag** while its three new place-mates all carry `Jeanne Gang` + `Designed by a Master` — pre-existing on `main`. **Verification:** mirror **31/31**, then **0 errors, 0 warnings across 1,552 tours + 1,306 pins + 130 places**; **18 faults injected against THIS move — 18/18 caught, control clean both sides**; 🎉 **`check-place-candidates.py` BYTE-IDENTICAL before and after at 22 EXACT / 61 NEAR** (correct — the pin moved between two coordinates the checker already ignores because both carry a place); seed clean at **350 / 2,858 / 3,230 / 130**. Detail: `archive/HANDOFF-260907.md`.

**Session 146 (2026-09-06) — backend.** The catalog RPC was found failing **4 times in 12** with a statement timeout: `get_catalog()` rebuilds ~11 MB of JSON per request and has grown into its own time limit. Materialised it (`backend/catalog_snapshot.sql`) — the builder is renamed aside and runs once per seed, `get_catalog()` becomes a lookup. Also fixes a torn read observed live (a client served new `tours` alongside old `places` mid-seed). **Owner step: paste the SQL after merging.**

**Status (2026-09-05, session 146, branch `claude/places-stack-cap-260905`):** web session (**content**) — **four places for the four sites sitting exactly at the stack cap.** Owner: *"Make the places for the four sites."* **Places 121 → 125** — **Alcatraz · Hoover Dam · Fort Jefferson · the Leaning Tower of Niles**, each three coincident markers against `TourSetMap.maxStacked = 3` with **no headroom**, so a fourth link at any of them would have put one marker permanently out of reach, invisibly. A place collapses its members into one capsule pin, so the cap stops applying. `tours` and `makers` **byte-identical**; exactly **3 link pins moved**, in exactly their four coordinate fields each — **every deleted line in the diff is a coordinate line**, checked one by one. 🔴 **Alcatraz took the Atlas SFO tour as a FOURTH member, and that is the substance** — it sits **5.7 m** away (the documented CalAcademy rounding artifact: the Plus Code decodes at 7 decimals, the tour stores 4), so membership was a real decision, not automatic. **The pin moves, never the tour**: the tour is `geofenced` at r=40 and the builder **asserts `triggerMode == "manual"` before relocating anything**, so a future edit cannot get it backwards silently — the place sits on the tour's coordinate and the three pins moved onto it. Including the tour is also **what buys a real third photograph** (its gallery has four), so Alcatraz is the one place here whose hero is neither member's. ⚠️ **The other three heroes are BORROWED and it is STRUCTURAL — do not go sourcing replacements.** Proved before the builder was allowed to accept a borrow: **the only markers within 5 km are the members themselves, every gallery is empty, and nothing else in the catalogue mentions the subject** — the Waterlooplein / Legion of Honor case the owner has closed. The assertion was relaxed narrowly: a borrow must name **one of the members' own heroes, never an invention**. Borrowed-hero count **re-derived, not carried forward: 49 of 125**. ⚠️ The full-text sweep also matched **The Leaning Tower of Pisa** and **The Leaning Tower of Toruń** — different buildings, correctly excluded. **Every candidate was rendered and looked at.** **Fort Jefferson's is the strongest hero in the batch** — the whole hexagonal fort in turquoise water, no burned-in text. 🔴 **Hoover Dam's is the weakest and it is stated, not buried:** all three candidates are **historical B&W or sepia archive frames with the creator's burned-in text**, and ⚠️ **the one chosen is titled "Today" over a construction-era shot** — the creator's own irony; there is no modern photograph of the dam in the catalogue. ⚠️ **Niles is a stated trade-off** — the only modern colour frame, but cropped so **the lean itself, the entire point of the building, is not in frame**. 🎉 **`Fort Jefferson` returned ZERO results unbounded and was found named at 10 m once bounded** — a first-pass miss is not evidence a place is unmapped; **Niles reverses BY NAME** onto 6300 West Touhy Avenue. ⚠️ **Hoover Dam straddles a state line and the copy takes no side** (OSM files the dam in **Arizona**, the reverse of the members' point gives **Nevada**); the members' `city: "Boulder City"` is corroborated by the **89006** postcode. ⚠️ **Three creator claims were NOT repeated as ours** — 🔴 Fort Jefferson does **not** repeat *"New York brick failed in the Florida heat"* (the creator's causal claim and a pin's own title), stating instead what is uncontested; Hoover Dam carries **no mortality figure** and no height; Alcatraz keeps a plain register on both the incarceration and the 1969 occupation. **Verification:** the **400 m sweep went past the checker's group** (the session-131 lesson) and found **nothing else within 400 m** of three of the four; uuid5 scheme **reverse-verified against 119 of 121 existing places** before minting, **0 collisions**; 🔴 **49 place-layer faults injected against THESE FOUR PLACES — 49/49 caught, control clean before and after**, the harness counting **errors AND warnings**, reading `check()`'s **tuple** rather than mistaking it for an exit code, and injecting **in memory**; mirror **27/27 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,278 pins + 125 places**, ⚠️ **exit code read directly, never through a pipe**; 🎉 **`check-place-candidates.py` EXACT 28 → 24, NEAR 63 → 60**, and the report diff proves it **removes exactly the four groups plus the three Alcatraz NEAR pairs and ADDS NOTHING**. `Tours.json` **byte-stable before and after**, with **every image URL on every tour and pin asserted identical to `HEAD`**; seed clean at **346 / 2,830 / 3,202 / 125** with **0 `images//`** in the catalogue *or* the SQL; all four place heroes live **200**. ⚠️ **`check-image-duplicates.py` deliberately NOT run and that is not a gap** — no image added, no image URL changed, and each borrowed hero is used in its own pin and as the place hero, the documented tier-1 shape. Detail: `archive/HANDOFF-260905-4.md`. Earlier status follows.

**Status (2026-09-05, session 145, branch `claude/new-tour-links-nl8h63`):** web session (**content**) — **twenty-three Miami link pins, seven of them on two coordinates.** 34 Instagram links under a heading reading "Miami" → **29 distinct posts** (five pasted twice) → **23 shipped, 1 already pinned, 3 blocked, 2 parked**. **linkPins 1,214 → 1,237 · makers 331 → 345 · `tours` and `places` byte-identical.** 🔴 **FOUR pins sit on the Faena's single coordinate, past `TourSetMap.maxStacked = 3`, and THREE on The Surf Club's, exactly at it** — and ⚠️ **all four Faena pins are different creators**, so unlike the AMFA case the cap bites on the Home map and shared lists rather than a creator page. 🔴 **OSM maps none of the inner venues separately** (three bounded queries returned nothing inside those footprints), so siting them apart would be the manufacturing session 132 rejected for Arthur Ashe — **a place is the fix for both, flagged not created**. `check-place-candidates.py` **16 EXACT → 19, NEAR unchanged at 53**, the three added groups being exactly Patch of Heaven ×2, Faena ×4 and Surf Club ×3. 🔴 **The heading was loose for the fourth batch running and named the wrong city twice** — link #1 is an already-live **Toronto** pin and one of the 23 is explicitly **Orlando**. **Three posts are blocked**, proven against three live catalogue controls fetched in the same pass with the same UA. 🔴 **The unbounded geocode trap fired twice and both would have shipped** — `Raccoon Island` matched **Raccoon Key near Key West** and `Baia Beach Club` matched **Madeira, Portugal**; a bounded-only re-run fixed both, and re-querying was likewise the whole fix for The Kampong. **Four hand re-crops** through a mirror that **reproduces the tool byte-for-byte at vfocus 0.5 on all 23**; ⚠️ **a fifth flag was WITHDRAWN after rendering the output and looking at it** — its text sits at the bottom of the frame and survives, so nothing had been destroyed. 🔴 **A real blind spot found in `validate-tours-mirror.py` and closed** — the Swift errors on an invalid `sourceURL` / empty `sourceAuthor` and the mirror checked neither; **read the Swift before calling a miss a blind spot**, selftest **24/24 → 27/27**. **MERGED as [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738) (squash `9d7a1b7a`), with the Studio Gang batch below**, and ✅ **verified against the live Supabase RPC rather than the merge's success line: 1,237 linkPins, 0 of the branch's pins missing, 0 pins wrongly inside `tours`**; the gh-pages mirror converged to the same figures. ✅ **FOLLOW-UP, session 145 — all four flagged sites are places now** (owner: *"11 hoyt is Brooklyn. Make places for all suggested"*): **places 125 → 129** — Faena Hotel Miami Beach (4 members), The Surf Club (3), Patch of Heaven Sanctuary (2) and the Arkansas Museum of Fine Arts (4) — so **every stack-cap finding these two batches raised is closed.** A **pure addition**: `tours`, `makers` and `linkPins` byte-identical, the 125 existing places unchanged as a prefix, and **nothing moved** (all 13 members already exactly coincident, all `manual`, asserted first); diff **65 insertions / 0 deletions**. ⚠️ **Swept 400 m around each site rather than trusting the checker's group** — and the group genuinely was the whole story all four times, so **no deliberate exclusion to record**. 🔴 **All four heroes are borrowed and that is structural** (every member a link pin with an empty gallery, no Atlas tour at any of the four sites); borrowed-hero count re-derived **53 of 129**, all 13 candidates rendered and looked at. ✅ **Every anchor confirmed by geocoding**, the Surf Club's address settled by the **forward** search naming `Four Seasons Hotel at The Surf Club, 9011 Collins Avenue` at 0.0 m where the reverse had landed on a neighbouring building at 9001. **11 Hoyt keeps `city: "Brooklyn"` — owner decision, CLOSED.** Mirror **27/27 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,278 pins + 129 places**; ⚠️ **53 place-layer faults injected against these four places specifically — 53 caught, control clean before and after**; 🎉 **`check-place-candidates.py` EXACT 24 → 20 with NEAR unchanged at 60**, the diff proving it fell by exactly the four groups resolved and gained nothing; seed clean at **346 / 2,830 / 3,202 / 129** with **0 `images//`**; all four hero URLs live **200** and hash-verified. ⚠️ **Rebuilt on a moved `main`** — #737 landed 41 pins and #739 four **different** places, so [#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740) ran **no CI at all** until the conflict was resolved (a conflicted PR triggers no checks); `main`'s file was taken wholesale and the idempotent assembler re-run on it. The two place sets are **disjoint, 0 member overlap**. Detail: `archive/HANDOFF-260905-2.md` and `archive/HANDOFF-260905-5.md`.

**Status (2026-09-05, session 144, branch `claude/new-tour-links-nl8h63`):** web session (**content**) — **thirteen Studio Gang link pins across eight buildings, and two stack caps hit at once.** Fifteen Instagram links under a heading reading "Studio Gang" → **13 distinct posts** (two pasted twice) → **13 shipped, 0 blocked**. **linkPins 1,201 → 1,214 · makers 328 → 331 · `tours` and `places` byte-identical.** 🔴 **The Arkansas Museum of Fine Arts is FOUR coincident markers, past `TourSetMap.maxStacked = 3`** — three of them one creator, so that creator's own page sits exactly at the cap and the fourth marker is permanently unreachable on any maker, place or list map; and **the Gilder Center is effectively three deep** (two live pins plus this one), which `check-place-candidates.py` under-reports as two because the existing pair differs in the 6th decimal (the CalAcademy artifact). **Both flagged, neither created** — a place needs owner approval. `check-place-candidates.py` **12 EXACT → 16, NEAR unchanged at 53**, the four added groups being exactly Populus, AMFA, Solar Carve and Gilder — nothing nudged together or apart. ⚠️ **The heading was loose for the third batch running** — 2 of 13 are `@11hoytbk` and `@arkmfa`. 🔴 **Spelman was the Warehaus interpolation trap** (three house points ~280 m apart for one number); a **bounded viewbox** search found `Spelman College Center for Innovation and the Arts` by name, and re-querying was likewise the whole fix for Mira. ⚠️ **Four heroes are not photographs of a finished building** — an architecture practice's own feed carries plan diagrams, axonometrics and construction aerials; the AMFA crayon plan shows no building at all. **Two hand re-crops**, including **the first HEIGHT-limited one** (a 16:9 source, so `--focus` does nothing horizontally either). ⚠️ **20 faults injected, 17 caught — and the 3 misses were checked against `validate-tours.swift` BEFORE being called blind spots**, because session 142 shipped an invented rule that way; all three are real and were asserted directly on the 13 instead. Mirror **24/24 selftest**, then **0 errors, 0 warnings across 1,552 tours + 1,214 pins + 121 places**; all 13 live hero URLs **hash-verified against the uploaded bytes**. **MERGED as [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738) (squash `9d7a1b7a`)**, and ✅ **confirmed live: all four AMFA pins serve on the identical coordinate, so the four-deep cap finding stands.** ✅ **AMFA IS A PLACE NOW** (session 145, owner instruction) — the cap no longer applies. 🔴 **The Gilder Center is still open** and remains under-reported by the checker as two.

## V1 — Functionality milestones (in execution order)

### M1–M3. Build infrastructure — ✅ Done

These three milestones built the structural shell that survives the
audio-tour pivot. Brief status:

| | Status |
|---|---|
| **M1. Wire ContentView (5-tab TabView)** | ✅ Done in PR #2. Tab *contents* will change in later milestones; 5-tab skeleton stays. |
| **M2. Populate seed data file** | ✅ Done in commit `890b10c`. The 45-place editorial file gets replaced by `Tours.json` in M-data-model — but the infrastructure for loading JSON at launch survives. |
| **M3. Location privacy string** | ✅ Done (build setting). The copy will likely be tweaked for the audio-tour framing during M-home — small change. |

---

### M-data-model. New data model — Tour, Stop, Maker, LibraryEntry, TourCategory, RecentSearch — ✅ Done (PR #6)

**What:** Add the new Swift model types described in
`atlas_claude_code_prompt.md` § Data Model. Add a one- or two-tour
`Tours.json` for shape testing. Reshape `DataService` to load it.
Delete the old `City` / `Place` / `PlaceCategory` /
`PlaceCollection` models.

**Why:** Every later milestone depends on this shape. The previous
data model doesn't fit the audio-tour product at all.

**Files touched:**
- `Models/Tour.swift`, `Models/Stop.swift`, `Models/Maker.swift`,
  `Models/LibraryEntry.swift` (new)
- `Models/TourCategory.swift` (new — closed enum of categories that
  drive the home screen's interest-based rails; spec § TourCategory)
- `Models/RecentSearch.swift` (new — local-only record of a search
  query, used by the "Because you searched [X]" rail; spec §
  RecentSearch)
- `Resources/Tours.json` (new — shape-test content only; real content
  arrives in M-launch-content)
- `Data/DataService.swift` (reshape)
- `Data/SeedData.swift` (rename → `Data/ToursData.swift` or rewrite
  in place)
- `Resources/SeedData.json` (delete once `Tours.json` works)
- `Models/{City,Place,PlaceCategory,PlaceCollection}.swift` (delete)

**Expected fallout:** Most existing views (`DiscoverView`,
`CityDetailView`, `PlaceDetailView`, `MapView`, `CollectionsView`)
break at compile time after the model swap. That's expected — the
next milestones rewrite them. To keep the app buildable mid-milestone,
the views can be stubbed to "Coming soon" placeholders until their
own milestone lands.

**How we know it worked:** App compiles; `DataService` exposes
`tours: [Tour]` on the environment; a debug print confirms tours
loaded.

---

### M-audio-foundation. Audio playback infrastructure — ✅ Done (PR #7)

**What:** Wire up audio playback as a foundation every later milestone
will use.

- Add `Audio/AudioPlayerService.swift` (`@Observable`, on the
  environment shelf) wrapping `AVQueuePlayer`.
- Configure `AVAudioSession` with `.playback` category (audio
  continues with phone locked, ducks other audio appropriately).
- Add `UIBackgroundModes` → `audio` to Info.plist build settings.
- Wire `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` for play /
  pause / scrub / skip-forward / skip-backward from lock screen,
  headphones, AirPods, and CarPlay.

**Why:** Audio playback is the product's core feature; everything
downstream is wallpaper around it. Best to get the iOS plumbing right
once.

**Files touched:**
- `Audio/AudioPlayerService.swift` (new)
- `project.pbxproj` (add `UIBackgroundModes` build setting)
- `TRAVEL_GUIDED_TOURApp.swift` (instantiate service, place on
  environment)

**How we know it worked:** A throwaway test view plays a known remote
audio URL → audio plays → lock phone → audio continues → unlock →
lock-screen controls show the playing audio with title/artwork → tap
pause from lock screen → audio pauses.

---

### M-tour-detail. Tour detail screen — ✅ Done (PR #8)

**What:** Build `TourDetailView`. Replaces `PlaceDetailView`. Shows
hero image, title, maker (tappable, links to `MakerView`), length,
walking distance, stops list, intro audio, Start / Download / Save
buttons.

**Files touched:**
- `Features/Tour/TourDetailView.swift` (new)
- `Features/Place/` (delete)

**How we know it worked:** A hardcoded navigation entry point opens
the detail for a specific tour ID. All fields render. Tapping Start
calls `AudioPlayerService` and starts playing the intro (or stop 1 if
no intro).

---

### M-player. Full-screen audio player — ✅ Done (PR #9)

**What:** The screen consumers will spend the most time on. Shows
hero image, scrub bar, play/pause, speed control (1x / 1.25x / 1.5x /
2x), next-stop / previous-stop, stops list with the current stop
highlighted, and (for geofenced tours) distance-to-next-stop.

**Files touched:**
- `Features/Player/PlayerView.swift` (new)

**How we know it worked:** From `TourDetailView`, tap Start → player
pushes onto navigation stack → audio plays → scrub bar tracks position
→ tapping a different stop jumps playback → "next stop" button
advances correctly.

---

### M-home. Map-dominant home screen with curated rails — ✅ Done (PR #10; redesigned in PR #19)

> PR #19's full-screen-map redesign replaced the stacked rails with
> a single distance-sorted tour list in a bottom drawer. The shipping
> home has no rails — `HomeRailsViewModel` and `RailCarousel` are
> unused by the app (still exercised by the unit suite). The old
> "Because you searched [X]" rail is retired along with the layout.

**What:** Build the new home screen, modeled on the Airbnb landing
page pattern. See `atlas_claude_code_prompt.md` § Key screens #1 for
the design contract. Major pieces:

1. **Search bar pinned to the top** above the map (taps to open the
   M-search results screen).
2. **Map** filling the upper portion of the screen, with tour-stop
   pins. Centered on the user's location, or a sensible default if
   denied / unavailable. Panning the map updates the location-anchored
   rails below.
3. **Curated horizontal-scroll rails** filling the lower portion.
   Three rail families:
   - **Location-anchored:** "Near you" (uses `LocationManager`),
     and "In [city/area in view]" that recomputes when the map pans.
   - **Personalized:** "Continue listening" (`LibraryEntry.listenedSeconds > 0
     && completedAt == nil`), "Recently viewed" (small local cache),
     "Because you searched [X]" (from `RecentSearch`).
   - **Interest-based:** one rail per `TourCategory` — "History,"
     "Architecture," "Art," etc. Hide rails with zero matching tours.

Also: tweak the location-permission copy in build settings to match
the audio-tour framing.

**Files touched:**
- `Features/Home/HomeView.swift` (new)
- `Features/Home/HomeMapSection.swift` (new — map at top, with pan
  detection that updates rail state)
- `Features/Home/RailCarousel.swift` (new — reusable horizontal-
  scroll rail component used by every rail family)
- `Features/Home/HomeRailsViewModel.swift` (new — computes which
  rails to surface, sorts tours within each rail)
- `Features/Discover/` (delete after move)
- `ContentView.swift` (point Home tab at the new view)
- `project.pbxproj` (update `NSLocationWhenInUseUsageDescription` copy)

**How we know it worked:** Set simulated location to NYC → map opens
on NYC with pins → "Near you" rail shows NYC tours → category rails
show interest-organized tours. Pan map to Lisbon → location-anchored
rails recompute. Deny location → map opens on a sensible default
view, location-anchored rails fall back to "Browse all" or hide.

---

### M-search. Search bar + results screen — ✅ Done (PR #11)

**What:** Minimal V1 search that powers the home screen's search bar
and the "Because you searched [X]" rail.

- Search bar in the home header opens a full-screen search results
  view.
- Matches on `Tour.title`, `Maker.displayName`, and
  `Tour.primaryCategory` (display name of the category).
- No filters, facets, fuzzy matching, sorting options, or saved
  searches — explicitly deferred per the spec's out-of-scope list.
- Successful queries (i.e., the user opens a tour from the results)
  are appended to local `RecentSearch` history. Cap stored at 20;
  oldest fall off.
- **Place search (2026-06-06, session 23).** A **Places** section above
  the catalog results geocodes the query via Apple's `MKLocalSearch`
  (cities / neighborhoods / landmarks); tapping one flies the Home map
  to that region instead of opening a tour. If the destination has no
  Atlas tours, a transient "No Atlas tours here yet" hint appears on the
  map. Place results are *not* recorded in `RecentSearch` (catalog-only).
  See `PlaceSearchService`, `HomeSharedState.pendingMapMove`,
  `MapRegionGeometry`.

**Files touched:**
- `Features/Search/SearchView.swift` (new — results screen)
- `Features/Search/SearchBar.swift` (new — the pinned bar component
  used in `HomeView`)
- `Data/RecentSearchStore.swift` (new — local persistence for
  `RecentSearch` records)

**How we know it worked:** Tap search bar → results screen opens.
Type "history" → tours with `primaryCategory == .history` appear.
Type a maker name → that maker's tours appear. Tap a result → tour
detail opens → return to home → "Because you searched [X]" rail
now shows the query.

---

### M-map. Standalone map screen — ❌ Cut (PR #15)

Cut by owner decision. Home's embedded map (and then the full-screen
map in the PR #19 redesign) covers the spatial-discovery need; a
separate Map tab was redundant. The former Messages tab also got
absorbed into Settings as a row in the same cut, dropping the shell
from 5 tabs to 3 (Home / Library / Me). `Features/Map/` was deleted.

---

### M-maker. Maker page — ✅ Done (PR #12)

**What:** New `MakerView` shows avatar, bio, and the list of that
maker's tours. Linked from `TourDetailView`'s maker attribution.

**Files touched:**
- `Features/Maker/MakerView.swift` (new)

**How we know it worked:** From tour detail, tap the maker's name →
maker page renders → tap one of their tours → tour detail opens.

---

### M-library. Library tab — Saved / Downloaded / Recently played — ✅ Done (PR #13)

**What:** Replace `CollectionsView` with `LibraryView`. Three sections:
**Saved** (bookmarked tours), **Downloaded** (audio cached on device),
**Recently played** (resume listening). Replace `CollectionStore`
with `LibraryStore` (data shape changes from `[PlaceCollection]` to
`[LibraryEntry]`).

**Files touched:**
- `Features/Library/LibraryView.swift` (new)
- `Features/Library/{Saved,Downloaded,RecentlyPlayed}Section.swift`
  (new)
- `Features/Collections/` (delete after move)
- `Data/CollectionStore.swift` → rename / rewrite as `LibraryStore`
- `ContentView.swift` (point Library tab at the new view)

**How we know it worked:** Save a tour from `TourDetailView` → it
appears in Library → Saved. Force-quit + relaunch → still there.
Recently-played history reflects what you actually played.

---

### M-geofencing. GPS-triggered stop playback — ✅ Done (PR #17)

> Always-location decision: shipped with both
> `NSLocationWhenInUseUsageDescription` and
> `NSLocationAlwaysAndWhenInUseUsageDescription` set, so geofences
> can fire while the app is backgrounded / phone locked.

**What:** For multi-stop tours where the maker set stops to
`.geofenced` mode, automatically play the next stop's audio when the
user enters that stop's geofence (default 30m radius). Reuse the
existing `ProximityMonitor` shape with the new `Stop` model. Fire a
local notification when the geofence triggers in the background.

**Files touched:**
- `Location/ProximityMonitor.swift` (rework for stop geofences)
- `Audio/AudioPlayerService.swift` (handle geofence-triggered enqueue)
- `project.pbxproj` (likely needs
  `NSLocationAlwaysAndWhenInUseUsageDescription` for background
  geofencing — owner-facing decision: do we ask for "always" location,
  or accept that geofencing only works while the app is foregrounded?)

**Open question for owner at start of this milestone:** "Always"
location is more powerful (geofences work with the phone locked) but
a heavier permission ask. "When-in-use" works while the player is on
screen but stops when the app backgrounds. Recommended: ask for
when-in-use first; prompt for always-allow only once the user starts
a multi-stop geofenced tour, with copy that explains the tradeoff.

**How we know it worked:** Simulator with simulated location moving
along a tour's stops → audio for stop N plays as the user arrives at
stop N. Phone locked → same behavior + a local notification.

---

### M-offline. Tour download for offline playback — ✅ Done (PR #18)

**What:** "Download for offline" on tour detail downloads all of the
tour's audio files (and intro) to the app sandbox. Player prefers the
local file when available. Downloaded tours appear in Library →
Downloaded with an offline indicator. Settings includes a "Manage
downloads" view for deleting cached tours and seeing storage usage.

**Files touched:**
- `Audio/TourDownloader.swift` (new — `URLSession` background
  downloads)
- `Features/Tour/TourDetailView.swift` (Download button + progress
  ring)
- `Features/Library/DownloadedToursSection.swift`
- `Features/Settings/SettingsView.swift` (Manage downloads link)

**How we know it worked:** Download a tour → put phone in airplane
mode → start the tour → audio plays end to end without buffering.

---

### M-launch-content. Record 5–15 audio tours / pieces

**Owner milestone — not Claude work.** The Atlas team:

- Picks 5–15 locations / themes (mix of single-piece + multi-stop)
- Writes scripts
- Records audio
- Edits and masters
- Captures stop coordinates and trigger preferences
- Uploads audio to the chosen CDN
- Writes maker bios + tour descriptions
- Authors the final `Tours.json` entries

**Authoring scaffold (ready):**
- `docs/authoring-tours.md` — UI-agnostic field-by-field guide
  (every `Tour` / `Stop` / `Maker` field, decision tips, validation
  checklist, quick workflow). Doubles as the spec for the future
  in-app maker upload form.
- `docs/Tours.template.json` — two filled-in example tours
  (single-piece + multi-stop) showing every field. Copy from this
  when authoring real entries.
- `scripts/validate-tours.swift` — pre-commit safety net. Catches
  typos, duplicate UUIDs, broken maker refs, kind ↔ stop count
  mismatches, coord-range errors, audio-duration math problems
  before they crash the app at launch. Run manually with
  `swift scripts/validate-tours.swift` or wire into a git
  pre-commit hook (one-liner in `docs/authoring-tours.md`).

**Hand-off shape:** Once `Tours.json` is updated with real content and
audio URLs resolve, the rest of the app should "just work" — no code
changes required if the prior milestones held to the data contract.

**Audio hosting (decided 2026-05-18):** GitHub Releases for the
design / prototype phase; switch to Cloudflare R2 before public
release. Full reasoning and switch-triggers in `docs/cdn-decision.md`
§ Status. Owner manages Releases uploads; URLs slot into
`Tours.json` like any other HTTPS URL — no code changes required
to use either path.

---

### M-qa. V1 functionality sanity pass

**What:** End-to-end walkthrough of the running app with real content
loaded. Functional checklist:

1. App launches → map-dominant home with pins, search bar, filter
   chips, and the tour list in the bottom drawer (or graceful
   fallback if no location). The list sorts nearest-first when
   location is granted, with distance labels on each card.
2. Pan the map → the drawer header's "N tours in view" count
   recomputes for the new area.
3. Tap the search bar → results screen works (title / maker /
   category match). Open a tour from search → tour detail opens.
4. Tap a tour (pin, drawer card, or search) → tour detail → tap
   Start → audio plays.
5. Lock the phone → audio continues; lock-screen controls work.
6. Multi-stop geofenced tour → simulated walking along stops → next
   stop's audio triggers on arrival.
7. Multi-stop manual tour → tap next stop in player → its audio plays.
8. Download a tour → airplane mode → tour plays end to end.
9. Save a tour → force-quit + relaunch → still saved.
10. Maker page → tour list correct → tap tour → tour detail opens.

**M-qa device pass — build 1.0 (4) (2026-05-21).** First on-device
walkthrough. Checklist 1, 3, 4, 5, 8, 9, 10 passed. Items 6/7
(multi-stop geofenced + manual) deferred — no multi-stop tour is in
the current catalog. Five UX issues surfaced and were fixed the same
session (remote — code on the feature branch, ships to device on the
next TestFlight build):

- **Mini-player added.** A persistent now-playing bar sits between
  the home drawer and the tab bar whenever audio is loaded —
  pause/resume inline, tap to reopen the full player. New
  `Features/Player/MiniPlayerBar.swift`; hosted by `ContentView`;
  the home drawer's peek height grows to clear it.
- **Hero-image bleed-through at the peek detent fixed** — the
  drawer's scroll list now fades out at peek instead of leaking a
  sliver of the first card above the tab bar.
- **Recenter animation** — the camera now glides to the user
  (0.45 s ease) instead of snapping; the recenter button's
  fade-in/out on map pan is gentler.
- **User-location dot rebuilt** — explicit Apple-Maps blue, plus a
  directional heading wedge driven by the device compass
  (`LocationManager.heading`, iOS only).

**M-qa device pass — build 1.0 (5) (2026-05-22).** Full walkthrough
on device. Checklist items 1–5 and 8–10 all passed, plus every
build-5 UX change verified — the always-present mini-player (idle +
active states), the square-topped island, the tour-detail action
bar, drawer-card carousels, pinch-to-zoom hero images, the compass
heading wedge, the Library/Settings island backgrounds, and
drawer-detent persistence across tab switches. Items 6/7 (multi-stop
geofenced + manual) still deferred — no multi-stop tour exists.
**No issues found.** V1 functionality is device-validated; only the
multi-stop checks remain, blocked on content.

**Files touched:** none expected. Bugs become small targeted fixes.

**Outcome:** V1 ready for owner review via TestFlight, or for the
polish phase below.

**Pre-QA self-audit (2026-05-18).** Before M-qa actually runs on
device, a code self-audit (landed via PR #21; doc archived to
`archive/pre-qa-audit-260518.md` once most P0s closed) surfaced
22 findings — bugs, fragile edges, accessibility gaps, polish —
categorized P0 (launch blockers) → P3 (polish/debt). Running
status; check items off as fixes land:

**P0 — Launch blockers**
- [x] P0-1. Home → Tour Detail navigation silently broken (PR #23)
- [x] P0-2. Dark Mode catastrophically broken (PR #22)
- [x] P0-3. Typography hierarchy collapsed (PR #22)
- [x] P0-4. SettingsView 23 hardcoded `.foregroundStyle(.black)` (PR #22)
- [x] P0-5. Geofenced playback fails offline for downloaded tours (PR #24)
- [x] P0-6. Geofence notifications invisible in foreground (PR #24)
- [/] P0-7. Developer-facing copy in user UI — HomeView + LibraryView fixed in PR #23. SettingsView debug-counts row deferred to a follow-up after PR #22.

**P1 — Bugs**
- [x] P1-1. "Continue listening" / "Recently played" sort by wrong field (lastListenedAt added)
- [x] P1-2. Maker avatar URL is ignored (AsyncImage with circle fallback)
- [x] P1-3. Player-tour identification by title is fragile (currentSourceId on AudioPlayerService)
- [x] P1-4. HeroImageView doesn't load remote images (AsyncImage with placeholder fallback)
- [x] P1-5. Audio session interruption (phone call) not handled (PR #24)
- [x] P1-6. Headphone unplug doesn't pause audio (PR #24)
- [x] P1-7. International-dateline bug in coordinate-in-region check (MKCoordinateRegion.contains extension)

**P2 — Accessibility**
- [x] P2-1. BottomSheet has no VoiceOver affordance (label + accessibilityAdjustableAction)
- [/] P2-2. Map preview close button sub-44pt touch target — obsolete; the preview-card-with-X pattern was removed in the PR #19 home redesign
- [x] P2-3. Download button disabled state not announced (label + hint when isOtherActive)
- [x] P2-4. No "Open Settings" deep link when location denied (button in SettingsView, iOS/visionOS)
- [x] P2-5. Localization gap — duration / distance formatters hardcoded English/metric (new AtlasFormatters)

**P3 — Polish & tech debt** (ten items; see audit doc; none block V1)
- [ ] P3-1. Hardcoded values bypass theme-tokens — deferred with the design pass
- [x] P3-2. `formattedDuration` duplicated — closed incidentally by P2-5's `AtlasFormatters`
- [ ] P3-3. O(n) lookups everywhere — premature; V1 has 12 tours
- [x] P3-4. TourDownloader no retry on transient failures (3 retries, exponential backoff 1s/2s/4s, transient errors only — terminal failures still fail immediately)
- [ ] P3-5. No tour-completed UX
- [ ] P3-6. Splash screen bare-bones — deferred with the polish pass
- [x] P3-7. ContentView calls `requestPermission` on every appearance (guarded by `didRequestLocationPermission` flag)
- [x] P3-8. Search doesn't index tags or descriptions (added tag + description buckets with rank ordering)
- [ ] P3-9. No delete swipe in Library
- [x] P3-10. ManageDownloadsView ordering undefined (sorted alphabetically by title)

**Lifecycle.** The audit doc itself was archived on 2026-05-18
after the P0 wave landed (PRs #22 / #23 / #24). The closed PRs
are the authoritative record of fixes; this checklist is the
live "what's left." Remaining P1s will batch into a cleanup PR
before M-qa runs.

---

## V1 — Development infrastructure

| Milestone | Scope |
|---|---|
| **M-tests.** XCTest unit suite + CI | ✅ Done. Test files shipped via PR #28 (`claude/m-tests-260518`); workflow added the same day. Xcode test target wiring + CI fix shipped via PR #33 on 2026-05-18: `TRAVEL GUIDED TOURTests` Unit Testing Bundle hosts 6 XCTest classes (`LibraryStore`, `HomeRailsViewModel`, `RecentSearchStore`, `RecentlyViewedStore`, `TourCategory`, `ToursData` decoding) plus `TestFixtures`. Runs locally via Cmd-U and on CI per PR. Cadence rule: see `CLAUDE.md` § "When to run tests." |

---

## V1 — Polish milestones (after functionality lands)

| Milestone | Scope |
|---|---|
| **M-polish-theme.** Theme pass | Decide and apply final colors, typography, spacing. If the rest of V1 followed "use tokens, never hardcode," this is a 3-file change. |
| **M-polish-pins.** Custom map pins | Replace Apple's default pins with the final designed `StopAnnotationView`. |
| **M-polish-player.** Player UI polish | The player is the most-watched surface; deserves its own design pass after the rest of the design system is decided. |
| **M-polish-icon.** App icon | Replace the empty Apple template with a real Atlas icon. |
| **M-polish-copy.** Tour descriptions + maker bios review | Editorial-tone pass over launch content. Owner / content team, not Claude. |
| **M-rethink-categories.** Categories vs. tags | Closed-enum `Tour.primaryCategory` is showing strain in V1 content authoring — many tours have 2–3 defensible category fits, and forcing a single primary felt reductive on at least four tours during M-launch-content (Rockefeller Center, Brooklyn Bridge, High Line, Times Square). Likely direction: drop `TourCategory` enum, derive home rails + filter chips from tags (`Tour.tags`), either popularity-driven or from a curated tag set. Touches `Tour.swift`, `TourCategory.swift` (delete), `HomeRailsViewModel.swift`, `CategoryChipRow.swift`, `scripts/validate-tours.swift`, tests, and the product spec. Pair with the design pass since chip-row visuals change. Owner endorsed direction on 2026-05-19; deferred so V1 content can ship first. **✅ Phase 1 (all 509 tours tagged with the controlled v2 vocabulary) + Phase 2 (browsable tag UI) SHIPPED in TestFlight 1.0 (72)** ([PR #352](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/352), 2026-07-05): `Models/Tag.swift` vocabulary + curated shelves + multi-select filter chips (D6) + "Walks" format filter + full-width result cards + near/far location rails; `validate-tours.swift` enforces the vocab. **`primaryCategory`/`TourCategory` kept** (old builds + map pins) — dropping them + migrating the remaining category-reading consumer surfaces is **Phase 3** (later; `Tour.primaryTag` already derived via `Tag.derivePrimary` for the migration). Plan: `docs/tag-phase2-plan.md`. |
| **M-polish-final.** Final V1 success-criteria pass + vibe check | Walk the 9 success criteria in `atlas_claude_code_prompt.md` with the polished app. Last gate before any V1 release. |

---

## Known follow-ups (V1, non-blocking)

Small known gaps that aren't blocking V1 release but should get
picked up during M-qa or the polish phase. (Lifted from
`archive/HANDOFF-260518.md` so they live in a doc that future
sessions actually read.)

- **Rails layout retired.** The AllTrails redesign (PR #19/#31)
  dropped the stacked-rails home for a map + single distance-sorted
  drawer list. `HomeRailsViewModel` and `RailCarousel` are no longer
  referenced by the app (the unit suite still covers
  `HomeRailsViewModel`). Deleting them would mean dropping that test
  too, so they're left in place for now. The old "Because you
  searched [X]" rail is retired with the layout.
- **`AudioPlayerService` progress aggregation.** `listenedSeconds`
  on `LibraryEntry` currently reflects position within the current
  audio item only — it doesn't aggregate across stops in a
  multi-stop tour. Fine for V1 ("resume listening" works at item
  granularity), worth a real pass before any analytics or
  completion-tracking feature.
- **Custom `AtlasTabBar` tradeoff.** The AllTrails alignment branch
  replaces the system `TabView`'s tab bar with a custom one. That
  gives up system-level features (badge dots, focus animations,
  accessibility heuristics Apple ships). Easy to revisit post-V1
  if any of those bite.
- **Stale remote branch cleanup** (noted 2026-05-20). 13 merged
  `claude/*` feature branches still on `origin` from PRs #36–#47
  and #50 — all squash-merged, content verified to be on `main`, no
  unmerged work. Safe to delete; the remote-session container's
  GitHub token can't delete branches (HTTP 403), so this needs to
  run from the owner's local machine or the GitHub web UI. Branch
  list + ready-to-paste delete commands are in the chat transcript
  for the 2026-05-20 resume session; if that's lost, re-derive via
  `git ls-remote origin 'refs/heads/claude/*'` and cross-check each
  against its PR's merged status before deleting. Not touched:
  `main`, `gh-pages`, and whatever `claude/resume-*` branch the
  current session is on.
- **Hero image carousel UI** ✅ Shipped 2026-05-20. `TourDetailView`
  and `PlayerView` both render a paged `TabView(.page(indexDisplayMode:
  .always))` when `additionalImageURLs` is non-empty, falling back to a
  single `HeroImageView` for tours with one photo. Images are inset
  from the screen edges with a corner radius. All 3 Times Square images
  are reachable in-app. `HeroImageView` also fixed to constrain
  `scaledToFill()` layout so card sizing is stable.
- **Content authoring tooling at scale (M-content-tooling).** The
  current tour-upload workflow — owner drags audio + transcript
  into a Claude chat, answers 3 questions, Claude pushes audio +
  writes JSON + opens a PR — works fine for ~10 tours. It doesn't
  scale to 100, breaks at 1,000. None of this blocks V1; pre-cursor
  work for Tier 1 #2 (maker platform), since these tools are also
  ~50% of what outside makers will need. Streamlining wins worth
  doing whenever batch uploads start hurting:
  - **Single-PR batches** — one PR for N tours instead of one per.
  - **Manifest-driven uploads** — CSV / JSON with filename, title,
    coords, trigger, category per tour; the pipeline reads the
    manifest and runs the upload.
  - **Geocoding from text** — manifest can say "41st & Fifth, NYC"
    and a geocoder produces coords.
  - **Auto-transcription** — send just the MP3; Whisper or Apple
    Speech generates the transcript automatically.
  - **Description + tag drafting from transcript** — structured
    LLM prompt produces short desc + long desc + caption + tags +
    suggested category, owner spot-checks a batch.
  - **A `scripts/add-tour.swift` CLI** — given audio + manifest
    line, generates JSON entry, validates, commits, opens PR.
    Owner can batch-upload without invoking Claude.

---

## V2 — execution plan (in progress)

**V2 = open the platform to outside makers + give consumers accounts.** It executes
Tier 1 below (backend → auth + moderation → maker UI) and pulls Tier 3's sign-in
forward. Each step is shippable on its own; the *design* steps are docs+SQL produced in
web sessions, the *app* steps need a Mac (`test_sim` + simulator review before merge).

Backend decided: **Supabase (Postgres)** — see `docs/backend-design.md`.

| Step | What | Status |
|---|---|---|
| **1. Detach catalog** | App reads the catalog from a URL (`RemoteCatalogLoader`); bundled copy = offline seed | ✅ Shipped — build 46 (PR #209) |
| **2. Backend foundation** | `makers`/`tours`/`stops` schema, public-read RLS, `get_catalog()` RPC, seed from `Tours.json` | ✅ **DONE (2026-06-27)** — Supabase project "Dozent" live + seeded (5/370/396); **app cutover shipped (PR #255)** — `RemoteCatalogLoader` reads `get_catalog` first, gh-pages fallback. Live in **TestFlight 1.0 (50)** |
| **3. Accounts & auth** | `profiles`, self-serve makers, per-tour moderation, `reports`, consumer-sync tables; Apple+email+Google | ✅ **DONE — shipped through TestFlight 1.0 (57).** Email (#262) + Apple (#274) + Google (#277) sign-in; cross-device sync of library/makers/progress/recently-viewed (#279/#287) with logout-clear (#283); "Report a concern" → `reports` (#290). `AuthService` + `SyncService`. (Report-email notifications = pending owner Resend setup.) |
| **4. Maker dashboard** | Phase 1 single-piece creation (record/import audio, pin+radius, photos, transcript, metadata, submit→review), then Phase 2 multi-stop | ✅ **Phase 1 authoring loop COMPLETE — LIVE in TestFlight 1.0 (63)** (owner-confirmed 2026-07-03). Architecture: the **Me tab is a Profile = a maker page** (one `MakerView`, modes). Shipped: profile tab (#300), standalone creator screen via `MakerPresenter` (#302), create/edit profile → `makers` (#304), create-a-tour draft form + My-Tours feed with status badges (#307), and the **full tour editor (#310)** — record (`AVAudioRecorder`) / import audio → `tour-audio`, photos (PHPicker → crop 1200×900 → `tour-images` → hero+gallery), transcript, and **Submit for review** (status→`in_review`). `MakerProfileService` + `MakerTourService`; storage buckets + RLS from PR #222. **Submit-EMAIL notification LIVE (2026-07-03, owner-confirmed)** — Database Webhook `tour-submit-notify` on `tours` UPDATE → `notify-moderation` (guards the draft→in_review transition). **Remaining (one small step):** an admin **Publish** path (`select publish_tour('<id>')` works today). **Phase 2 (multi-stop authoring)** needs no backend change — future. |
| **5. Moderation (email-me)** | Owner chose **email notify**, not a queue UI: emailed on submit/report, act via `publish_tour`/`takedown_tour` | ✅ **DONE — both email notifications LIVE, owner-confirmed.** Report emails (2026-07-01, `reports` INSERT webhook) + **tour-submission emails (2026-07-03, `tours` UPDATE webhook)** → the `notify-moderation` Edge Function (SQL helpers PR #224 + Resend secrets). Act via `select publish_tour('<id>')` / `takedown_tour('<id>')`. |
| **6. Paid tours** | Apple IAP; `Tour.priceUSD` goes live; ownership tracking (Tier 2 #4) | ✅ **Phases 1–3 DONE — buying works end to end on device.** **P1** (2026-07-24): 10 tier IAP products in App Store Connect (`tour.tier.099`…`tour.tier.1999`), left in "Prepare for Submission" — correct until go-live, and it means purchases work **in Apple's sandbox only**. **P2** (2026-07-28): `backend/paid_tours.sql` applied — `tours.price_tier`, `purchases`, `payouts`, `maker_payout_accounts`, `maker_net_cents()` (68% of sticker), `maker_earnings`; Edge Functions `record-purchase` (Verify JWT **ON**) + `appstore-notifications` (OFF). **P3** (2026-08-13, [PR #469](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/469) → `9b2c289`): `PurchaseService` (StoreKit 2), `EntitlementStore` (per-account, offline-capable), `PendingPurchaseQueue`, a 30 s preview enforced on the player's clock, and the Buy button; Group Listen + Download withheld while locked **in both the action row and the ••• menu** (the menu gate came from review — see CLAUDE.md). Price badges on browse surfaces followed in [#498](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/498). **Owner-verified on device against Apple's sandbox** — a real purchase wrote a `purchases` row carrying Apple's transaction id and `environment=Sandbox`, which also proved the App Store Server API `.p8` parses and the JWT gate accepts a signed-in user's ES256 token (both open questions since P2; **no JWKS work needed and the toggle stays ON**). ⚠️ **Pricing is per-tour, set by the owning maker** — the current uniform $0.99 on walks is one maker's temporary test state, **not a rule**; see CLAUDE.md § LIVE PRICING before touching any price. Remaining: **P4** maker pricing UI, **P5** Stripe payouts, **P6** go-live (the first non-consumable IAP must be submitted *with* an app version). Known gap: `PurchaseOutcome.alreadyOwned` is declared and referenced but never returned, so "StoreKit says you own it and we have no row" has no recovery path. |
| **7. Maker payouts** | Stripe Connect (Tier 2 #5) | ⬜ Not started |
| **8. Consumer richness** | Follow-a-maker push, in-app search, share links (sign-in/sync already in Step 3) | ⬜ Partially pulled forward |

**Catalog rollout (de-risked, two phases)** once the DB is live: (1) keep the app on
gh-pages while a job exports `get_catalog()` → `Tours.json` → gh-pages (proves the DB,
zero app change); (2) point the app's `RemoteCatalogLoader` at the Supabase RPC, gh-pages
stays a fallback mirror. Details in `docs/backend-design.md`.

Design references: `docs/backend-design.md`, `docs/accounts-design.md`, `backend/`.

### V2 — remaining to-dos (checklist)

As of 2026-06-27. **Critical path to "outside makers can publish a tour": B (Supabase
config) → A (Mac app work).** Everything else (payments, consumer extras, media
hosting) can follow.

**A. App-side** — historically Mac-only; **as of 2026-07-19 a web session can also ship a device-testable build** via the on-demand signed-TestFlight CI (`.github/workflows/testflight.yml`, PR #393; runbook `docs/testflight-ci.md`). Trigger: PR label `build` or Actions → Run workflow. Owner still reviews on-device before merge. (each gated by `test_sim` / CI + review)
- [x] Add `supabase-swift` (first third-party dependency) — **done, PR #262 (2026-06-27)**: SPM 2.48.0, app-target only; used by `AuthService` (the catalog read still uses its own `URLSession` fetcher)
- [x] Point `RemoteCatalogLoader` at the `get_catalog` RPC (+ `apikey`/anon header) — **done, PR #255 (2026-06-27)**: Supabase-first with gh-pages fallback; `SupabaseCatalogFetcher` + `SupabaseConfig` (client-safe anon key). Live-verified 370 tours from Supabase in-sim
- [x] Sign-in UI (Apple / email / Google) in the "Me" tab — **all three done** (email #262 · Apple #274 · Google #277), shipped in builds 51/52/53. `AuthService` + `SignInView` (Apple + Google buttons + email sign-in/create/confirm), Me-tab account row + sign-out.
- [x] Sync a signed-in user's library / saved makers / recents → the `user_*` tables — **done (#279 library+makers, #287 recently-viewed; #283 logout-clear), builds 54–56.** `Data/SyncService.swift`: pull→merge→push on sign-in + debounced write-through; `user_library` / `user_saved_makers` / `user_recently_viewed`. Cross-device round-trip device-verified by owner.
- [~] Maker authoring UI (`Features/Maker/` + `Features/Profile/`) — Phase 1 single-stop, then Phase 2 multi-stop. **In progress (session 51):** Me-tab profile = maker page (#300); standalone public creator screen via `MakerPresenter` (#302); create/edit creator profile → `makers` row (#304, in review). **Next:** create-a-tour form → `draft`, then audio/photos/transcript/submit.
- [x] Wire the "Report a concern" overflow action → `reports` table — **done, PR #290 (build 57)**: `ReportSheet` + `ReportsService` insert (`returning: .minimal`); email removed from the client. Email notifications pending owner Resend/Edge-Function setup.

**B. Supabase config — owner (dashboard; Apple/Google need their dev consoles)**
- [ ] Enable auth providers — email (toggle), Apple (Services ID), Google (OAuth client)
- [x] Deploy `notify-moderation` Edge Function + set Resend secrets + add `reports` INSERT DB webhook — **done 2026-07-01**, owner-confirmed email delivery. (Optional `tours` UPDATE→in_review webhook deferred until maker authoring ships.)
- [ ] Make yourself admin: `update profiles set is_admin = true where id = '<your auth uid>';` (once you have a signed-in account)

**C. Needs owner decisions, then design**
- [ ] Paid tours (Step 6): per-tour purchase / subscription / both → then design Apple IAP
- [ ] Maker payouts (Step 7): confirm Stripe Connect → then design

**D. Deferred / later**
- [ ] Media hosting decision — gh-pages vs Supabase Storage vs a CDN (owner leans "one place"); see `docs/cdn-decision.md`
- [ ] Consumer richness (Step 8): follow-a-maker + notifications, in-app search, share links
- [ ] Moderation web admin tool — only if volume outgrows the email approach
- [~] **Group Listen** — **Phase 1 shipped 2026-07-19 ([PR #396](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/396), TestFlight 1.1 (8)); it did NOT actually work on device, and was fixed + device-verified 2026-07-25 (session 72).** A group listens to a tour in sync, leader-driven; Phase 1 = free **"Listen Together"** over **MultipeerConnectivity** (offline, ≤~8). `Features/GroupListen/` (state + transport seam + `MultipeerTransport` + `GroupListenCoordinator` engine + sheet + banner); "Listen together" in the tour ⋯ menu; `Info.plist` local-network + Bonjour keys. **#396 merged "additive and menu-gated" without a two-phone test, so the owner became its first tester — the durable lesson for device-only features.** **[PR #423](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/423)** fixed the causes (silent discovery/Local-Network failure with no `didNotStart…` delegates or connection state; false "Leader left"; epoch poisoning; intro desync; a roster data race) and **[PR #428](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/428)** tightened sync (two-tier drift correction — speed-trim gliding instead of a 1.25s dead zone), added **QR joining** (Core Image + AVFoundation + a `.group` deep link, so the system Camera app works), fixed the **untappable banner Leave button** (the bottom-module window claimed a fixed touch strip), and closed the remaining silent dead-ends. **Owner-verified on build 1.1 (38): QR join ✅, sync ✅ ("good enough to ship"), Leave ✅; solo-playback regression check still owed.** **Remaining phases:** Hosted mode (Supabase Realtime, `backend/group_sessions.sql`, large groups) + **Pro Guide** paid tier; plus leader-handoff/takeover. **Session 74 (1.1 42→46):** the **banner was removed entirely** in favour of a **green group icon** on the tour page (so the banner-overlap item is retired, and there is deliberately no app-wide session indicator); the sheet was compacted to a `.medium` detent with all three screens as two aligned columns; and two bugs it surfaced were fixed — an apparently-dead tab bar (the detail layer wasn't dismissed because the observer lives in a window the modal covers) and the missing mini-player/tab bar (now rendered **inline** when the secondary window is absent). **⚠️ QR floor 110pt.** **Deferred polish:** anonymous followers (account-gating is a design decision, owner kept it). **⚠️ STILL OWED: two-phone sync end-to-end — never run since the session-72 fixes.**
- [~] **Lists** (was "Journeys") — **Phase 1 SHIPPED 2026-07-19 ([PR #395](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/395) → `main`, TestFlight 1.1 (7), owner device-verified).** User-curated, ordered collections of whole tours (multi-stop tours kept intact). Built **entirely in a web session** through the new TestFlight CI pipeline (first feature to do so). `Models/TourList`, `Data/TourListService`, `Features/Lists/` (detail / editor / membership sheet); `backend/journeys.sql` applied.
  - **Saving CONSOLIDATED 2026-07-26 ([PR #447](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/447), TestFlight 1.1 (50)/(51), owner-verified).** There is now **one** way to keep a tour: **saved = in at least one list**, with **Liked** as the default bucket (backed by `LibraryStore`, so it works signed out). The bookmark tap is **add-only** — a second tap opens the membership sheet, never un-saves. The profile's separate "Journeys" door is gone; **Library is the single home**.
  - **Renamed Journey → List 2026-07-27 ([PR #458](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/458)).** Swift side only (`TourList` / `TourListService` / `Features/Lists/`); **the Supabase tables stay `journeys` / `journey_items`** so builds already on testers' phones keep working.
  - **Cached on disk 2026-08-20 ([PR #549](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/549), TestFlight 1.1 (92)).** `TourListService` kept lists **in memory only**, so every launch started empty and Library's Lists tab re-laid-out twice as three stacked round-trips landed — the owner's "the library tab jitters". It now hydrates a **per-account `ProfileSnapshotStore` snapshot synchronously at init**, loads concurrently, and refreshes at launch. ⚠️ **Every write path must call `persistSnapshot()`.** Same PR indexed `DataService`'s `by id` lookups, which were **linear scans over 1,418 tours** read per row on every body evaluation — an app-wide win, not only Library.
  - **Remaining (polish backlog, `docs/lists-design.md` §14):** edit-details, drag-reorder, enter per-tour note, cover images, share (`.journey` deep link + landing), discover/save others' (`saved_journeys`), walking-path map, batch offline download. Plus **search** in the membership sheet once a user has more than a handful of lists (a "Clear all" was proposed with it and **rejected** — one-tap removal from every list contradicts the deliberate-removal rule).

**E. Housekeeping**
- [ ] Fix 2 dead gallery images (The Oculus, The Charging Bull — Wikimedia 404)
- [ ] Delete merged `claude/*` branches (GitHub UI — proxy blocks deletion from sessions)

---

## Post-V1 — Future direction (owner takes my lead, reserves right to change)

> **Compass:** the *why* and the *in-what-order* live in **[`docs/product-vision.md`](docs/product-vision.md)**
> (north-star thesis, the five facets, NYC beachhead, "know your city" retention, the
> Explorer→Dozent ladder, and the sequenced roadmap). Read it before big product calls.
> **First domino: make the core NYC walking experience undeniably great** (validate the GPS
> trigger on the ground) — everything else is downstream of that.

The big arc after V1 is **opening the platform to outside makers.**
That requires several large pieces of infrastructure, roughly:

### Tier 1 — Unblock the maker side

| | Why first |
|---|---|
| **1. Backend.** Server-stored tours, audio uploads, full CRUD. Stack TBD: managed BaaS (Firebase / Supabase / AWS Amplify) vs. custom DB + REST API. | The static-JSON model doesn't scale past ~50 hand-maintained tours. Every other post-V1 feature depends on this. |
| **2. Maker authentication + maker dashboard.** Sign-up, audio upload, tour metadata editor, per-tour analytics. Phone for capture, web for composition; both are needed (see "Maker platform — detailed design" below). | No outside makers can ship anything without this. The keystone of Atlas-as-platform. |
| **3. Moderation pipeline.** Report-this-tour, takedown tooling, internal review queue, content policy. | Required before opening uploads to the public — Apple App Store review will ask. |

### Tier 2 — Monetization

| | |
|---|---|
| **4. Paid tours via Apple IAP.** `Tour.priceUSD` flips from 0 to real values; Buy button in consumer app; per-account ownership tracking. Apple takes 30% / 15%; Atlas takes a cut of the remainder; maker gets the rest. | The revenue-share model that the spec calls for. |
| **5. Maker payouts.** Pay makers what they're owed. Stripe Connect is the obvious default for marketplaces of this shape. | Required as soon as paid tours exist. |

### Tier 3 — Consumer-side richness

| | |
|---|---|
| **6. Real sign-in (replaces the V1 placeholder).** Optional sign-in; enables cross-device sync, follow-a-maker, purchase history. Anonymous use still works. | |
| **7. Follow-a-maker + new-tour notifications.** Push when a followed maker publishes a new tour. | |
| **8. In-app search.** Once catalog grows past browsable. | |
| **9. Social — share a tour.** Deep links into a specific tour from a shared URL. | |

### Outside content — link pins (new, 2026-08-24)

**Status (2026-08-29, session 122):** content session (web) — **twenty link pins from twenty
owner-supplied links**, on branch `claude/tour-links-upload-tbcerj`. **+20 pins, +2 makers**;
tours, places and countries unchanged at 1,552 / 38 / 36. Catalogue now **244 pins / 189 makers**.
**All twenty were alive and pinnable** — fifth fully intact batch running. **Fifteen are one
creator, Instagram `@breatheart_hk`** (Hong Kong walking account; several from a series 「100個香港
看海的地方」). **No PR opened** — this session's harness forbids opening one unasked.
**🔴 Four link-pin sessions were in flight at once on near-identical branch names**, so deduping
against `main` alone is no longer sufficient: source URLs were checked against the open PR's branch
too, and re-checked after it merged. **⚠️ `main` moved eight commits across three rebases** and the catalogue
edit was redone each time by taking `main`'s file and re-running the idempotent assembler.
**🔴 A place candidate is flagged and not created: an Atlas tour of the Duddell Street Steps already
exists 9 m from the new pin**, same subject and same name — the catalogue's tightest NEAR pair.
**⚠️ Four heroes are weak**, one badly: the Bird Bridge pin's thumbnail is a red X the creator drew
over a photograph to retract an earlier post, so it renders as a red X on the map.
Detail: `archive/HANDOFF-260829-4.md`.

**Previously (2026-08-29, session 121):** content session (web) — **thirty-two link pins from
thirty-five owner-supplied links**, on branch `claude/tour-links-upload-wa3e0g`. **+32 pins, +29 makers, +1 place** and three countries (Taiwan, Finland, Hungary); tours
unchanged at 1,552. ⚠️ **Merged alongside a parallel same-day batch**, so the catalogue landed at
**201 pins / 183 makers / 38 places / 36 countries** — neither session's own totals survived the
merge, which is why that Key-facts line says re-derive rather than quote. **No PR opened** — this session's harness forbids opening one unasked.
**2 links are dead at the source and 1 is parked.** ⚠️ **A dead Instagram reel is identified by
SIZE, not by a string**: the two dead ones return a ~215 KB embed shell with no owner blob on six
spaced fetches, against ~257–262 KB with one for live posts in the same run, and neither carries a
*"Video currently unavailable"* marker. The parked one names no place at all — its frame says only
*"IN GREENWICH VILLAGE"*, which fits Jefferson Market Garden and St Luke in the Fields equally, so
it waits on the owner rather than being guessed (session 112's parking precedent).
**🔴 Yankee Stadium became a place, because the map could not otherwise show all of it:** five of
the links are Yankee Stadium posts and an Atlas tour already sits there — six markers on one
coordinate against **`TourSetMap.maxStacked = 3`**, so two pins would have been silently unreachable.
The pins moved onto the tour's coordinate (the tour did not move; OSM's stadium polygon is 27 m
from it), and the place hero is a **third photograph** promoted from the Atlas tour's own gallery.
Two other new EXACT pairs — Chichén Itzá and Rosewood Mayakoba, two pins each — were **left as
pairs**, being inside the cap and having no Atlas tour to borrow a hero from.
⚠️ **Flagged, not resolved:** the YouTube pin's hero is a dark, indecipherable smear and **no better
thumbnail exists** (`maxresdefault` and `sddefault` both 404 on a 4:3 upload) — the likeliest
removal; one pin is a **stitch** of another creator's video; two ship a model and a historical map
rather than the place; and **three pins report `plays_inline=False`** for licensed music, the first
time that case has appeared at all. Verification: validator mirror **self-tested 40/40** against
injected faults, then **0 errors, 2 warnings**, both pre-existing on `main`; **0 of 33 target paths
pre-existed** and the handle suffix **prevented one live Atlas hero overwrite**
(`operaparken_hero.webp`); gh-pages tree diff **exactly 33 additions, 0 deletions**. Detail:
`archive/HANDOFF-260829-2.md`. Earlier status follows.


Bringing content creators already have into Atlas, rather than asking them to start again.
Owner's stated goal: *"creators that currently post on tik tok, instagram, linked in, youtube
etc. can find maximum compatibility for content they've already created… i want to remove the
hurdle."* Three routes, only the first built.

| | |
|---|---|
| **Link pins — BUILT, [PR #584](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/584), open.** You find someone's post and it becomes a map pin that **plays inside the app** via that platform's own embed. No API key, no registration, no app review on any of the three. **An embed, never a copy** — TikTok exposes no video-file field and their terms forbid getting one otherwise. Detail: `archive/HANDOFF-260824-4.md`. | ⚠️ The embedded player has **never been on a screen**; simulator fixture in §4 of that handoff. |
| **Creator import (camera roll).** A creator picks their own clip; the app extracts its audio as narration, a frame as the cover, and the duration. **Mostly exists already** — six of the seven wizard steps do their job; what blocks it is three walls: the audio step accepts `[.audio]` only, the photo picker is `matching: .images`, and `MakerTourService` hardcodes `videoURLs: nil` so **no tour can hold a video at all**. | Specced, not built. |
| **Connect TikTok (official Display API).** A creator authorises `video.list` and picks from their own posts — pre-fills title, caption, cover and duration, more than the camera roll can. Needs TikTok developer registration + app review. | Not started. |

**⚠️ The distinction that decides which to use: an embed cannot do what Atlas is for.** It needs
signal and the screen on — no offline, no geofence audio, no Group Listen, no download. A link
pin is something people *look at*; a tour is something that plays while they walk. That is why
`TourKind.link` exists rather than link pins pretending to be tours.

**🔴 A closed enum on a remotely-loaded catalogue is a forward-compatibility landmine.** An
unknown `kind` throws, failing the whole catalog decode, so any already-shipped build silently
stops updating. Decode unknown values to a safe default before the App Store — applies equally
to `triggerMode` and `primaryCategory`.

### Tier 4 — Platform expansion

| | |
|---|---|
| **10. Reviews / ratings.** Worth weighing — the spec historically excluded them for vibe reasons, but a creator marketplace usually needs quality signals. | |
| **11. Maker collaboration.** Multi-maker tours; joint payouts. | |
| **12. Native experiences on iPad / Mac / Vision Pro.** If consumer demand materializes there. | |

### Maker platform — detailed design (Tier 1 #2 deep dive)

The maker dashboard is the keystone of Atlas-as-platform. Right
now all content is curated by the Atlas team and hand-edited into
`Tours.json`. That works for ~10–50 tours; it falls apart at
hundreds and is unsupportable at thousands. The maker platform is
what flips Atlas from a curated audio app into a creator
marketplace.

Three phases, escalating in scope. Each ends in a shippable
surface.

#### Phase 1 — Single-piece tour creation (phone-first)

The minimum a maker needs to publish one short audio tour about
one location. Targets the simplest tour shape so the platform can
ship the basics before tackling multi-stop curation.

- **Onboarding.** Sign in with Apple (no passwords). Maker
  profile: display name, bio, optional avatar + website.
- **Audio.** In-app recording (`AVAudioRecorder`) so makers can
  record from the place itself, or import from Files / Voice
  Memos / Dropbox.
- **Transcription.** On-device via Apple's `SFSpeechRecognizer`
  — free to the platform, privacy-friendly, works offline. Maker
  reviews + edits the transcript before publishing.
- **Location.** MapKit with two modes:
  - "Use current location" — auto-pin where the maker is
    standing. Right answer when recording in the field.
  - "Drop pin" — long-press to place, drag to refine. Address
    surfaced for confirmation.
  - Trigger radius as a draggable circle around the pin.
- **Images.** PHPicker for camera roll. Carousel of up to 5
  (per the Option A model locked in 2026-05-19 — see
  `M-rethink-categories` neighbor). In-app landscape crop.
  First image is the card cover everywhere.
- **Metadata.** Title, short description, long description, tags
  (with autocomplete from existing taxonomy). Trigger mode with
  smart defaults — geofenced for outdoor, manual for indoor.
- **Review screen.** "Listen" button — maker walks their own
  tour end-to-end before publishing.
- **Submit → moderation queue** (Tier 1 #3).

#### Phase 2 — Multi-stop tour creation (phone + web)

Where it gets genuinely harder. Most makers will start with
single-piece tours; the platform's distinctive product is the
multi-stop walking tour.

- **Stop creation.** Same per-stop capture UX as Phase 1, but
  cheap to repeat. Collapsible cards in a list.
- **Ordering.** Drag-to-reorder. Makers don't always create
  stops in walking order — might record stop 4 first because
  they walked by it.
- **Route preview.** Once stops are placed, draw the connecting
  walking path via `MKDirections`. Surface total walking distance
  + ETA. Flag stops that are unreachably far apart (>500m gap
  without a transit hint).
- **Intro audio.** Optional clip before stop 1 — the "welcome,
  here's why I picked these five blocks" opener.
- **Per-stop trigger override.** Tour-level default, but a
  single stop inside (e.g.) a quiet church can flip to manual.
- **Validation.** Stops in walking order, no orphans, no
  oversized gaps without justification, no duplicates within
  radius.

#### Phase 3 — Maker tooling depth

The stuff that makes a maker stay on the platform after their
first tour. Less foundational than Phases 1–2; more
retention-driving.

- **Maker analytics.** Per-tour: starts, completions, average
  drop-off point, device split, top cities, peak days. One
  dashboard per tour.
- **Version history + revert.** Tours are living things; makers
  re-record stops, swap photos, fix typos. Track edits with
  rollback. Post-MVP, but design earlier phases with it in mind.
- **Drafts + autosave.** Tour authoring is *long*. Losing 20
  minutes of work to a phone call is unforgivable. Autosave
  every 30s; drafts list accessible from any signed-in device.
- **Re-edit after publishing.** Day one. Without version history
  at first — that's Phase 3.
- **Moderation hookup, two-way.** Makers respond to takedown
  notices, request re-review after edits, see flag reasons.
  Connects to Tier 1 #3.

#### Cross-cutting: phone vs web

Phone is right for **capture** — recording, pinning, photos.
Phone is wrong for **composition** — long descriptions,
transcript polish, metadata tuning, route review.

- **In the field, phone:** record audio at each stop, drop pin,
  take photos, save as draft.
- **At home, web:** open Atlas Studio on a laptop, polish
  transcripts, write descriptions, tune tags, preview the route,
  publish.

The earlier ROADMAP note ("Likely web-first — editing tours is a
desktop task") is half-right. The full answer is **both surfaces,
each optimised for the half of the workflow it does best**, with
drafts syncing between them.

#### Hard dependencies

Nothing here ships without these in place first:

1. **Tier 1 #1 — Backend.** Tours move from static JSON to
   server-stored. Audio uploads to a managed bucket the maker
   doesn't have to think about.
2. **Tier 3 #6 — Real sign-in.** Maker identity. Sign in with
   Apple is the right primitive.
3. **Tier 1 #3 — Moderation.** Required before opening uploads
   publicly. Apple App Store review will ask.

Sequence: backend (the platform) → auth + moderation (the
controls) → maker UI (the surface).

---

### Open questions for the owner (answer before each tier starts)

- **Tier 1 #1** — backend stack? **DECIDED 2026-06-21: Supabase (Postgres).**
- **Tier 1 #1 / maker onboarding** — application gate vs self-serve? **DECIDED 2026-06-21: self-serve + per-tour moderation** (anyone signed in can create one maker profile; publishing is admin-gated).
- **Tier 1 #2** — phone-only MVP, web-only MVP, or both from day one? *(open)*
- **Tier 1 #2** — auto-transcription via Apple's on-device API (free, lower quality) or Whisper API (paid, higher quality)? *(open)*
- **Tier 2 #4** — paid tours per-purchase, subscription, both? *(open)*
- **Tier 2 #5** — Stripe Connect or another marketplace processor? *(open)*
- **Tier 3 #6** — Sign in with Apple only, or also email / Google? **DECIDED 2026-06-21: Apple + email + Google.**
- **Tier 3 #6 / accounts scope** — consumer accounts now or later? **DECIDED 2026-06-21: now** (optional sign-in + cross-device library/saved sync; anonymous use still works).
- **Tier 4 #10** — do reviews and ratings ship at all, or never? *(open)*

---

## Working agreement

- This file is **living**. Edit it whenever the plan changes.
- **Doc hygiene.** Every session that ships a milestone, cuts scope,
  or changes the "what's true today" state of the project updates
  `ROADMAP.md` and `CLAUDE.md` *in the same commit* — never as a
  follow-up. Stale docs poisoned a recent session (Claude reported
  "all milestones done" without knowing about PR #19's redesign);
  the rule prevents a repeat.
- Functionality first; design / tone / icon / polish after.
- New code uses theme tokens even with placeholder values.
- Each milestone ends in a runnable, simulator-reviewable state.
- Owner reviews via simulator or TestFlight, not by reading code.
- If a session uncovers a new gap that isn't in this list, add a new
  milestone rather than expanding an existing one.
- The product spec (`atlas_claude_code_prompt.md`) stays canonical for
  *what* we build. This roadmap is *when* and *how*.
- Temporary "session bridge" notes (like the original `HANDOFF.md`)
  don't live at repo root — fold their permanent content into
  `ROADMAP.md` / `CLAUDE.md` and move the snapshot to `archive/`
  with a `YYMMDD` suffix.
