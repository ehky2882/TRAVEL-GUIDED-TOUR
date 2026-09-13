# STATUS history — finished board items

The items that were finished and had accumulated in [`../STATUS.md`](../STATUS.md)
§ 1 "Awaiting owner", verbatim, in the order they sat there.

Moved out on 2026-09-08. That section had reached **147,843 of the file's 205,618
bytes — 72%** — 48 items, of which **41 had pull requests GitHub
reports as merged or closed.** STATUS.md's own header forbids exactly this: *"when
an item here is finished, it leaves this file and its story goes there… never let
this file grow a history section — two histories drift, and drift is the problem
this file exists to fix."*

**Nothing was deleted.** Each item below is unedited.

⚠️ **Nothing here is current, by definition** — every item is finished. Four were
labelled `OPEN` when they were merged. For live state run
`bash scripts/session-start.sh`.

⚠️ **Search this file, do not load it whole:**

```bash
grep -n "Tower Bridge" archive/STATUS-HISTORY.md
grep -n "pull/74" archive/STATUS-HISTORY.md
```

---

✅ **MERGED — [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836), squash `f669493c` — the splash circle breathes again (2026-09-12). CODE — needs owner OK + a look on device.** Owner: *"i never wanted it to go away."* The 1.0↔0.2 breath #559 removed is back, on **Core Animation** (a SwiftUI fade stepped 0.4–0.6s under launch load). Device rounds so far: **147** showed no breathing — the floor was timed from launch, so the splash drew ~0.77s → the floor now counts from the splash's first drawn frame, one full breath (1.6s, owner decision). **149** breathed but late — the splash couldn't draw until the whole app was built → `LaunchDeferredContent` draws the splash first (static picture ~1s, was ~10s in the sim). 🔴 **Owner also caught the zoom had lost its solid brass** (since 147) → the zoom swaps to the original solid disc, handing off only on a rising bright breath (owner decision; takeover measured at 0.88–0.90). `main` merged in (#835, #798). ✅ **Owner device-verified on TestFlight 1.1.2 (151): *"reviewed it. looks great!"*** — approved to merge. Handoff: `archive/HANDOFF-260912-4.md`.
  - ✅ **Owner device-verified on TestFlight 1.1.2 (151): *"reviewed it. looks great!"*** — merged 2026-09-12.

⚠️ **`list_pull_requests(state=open)` re-derived 2026-09-04 — [#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728) has MERGED (squash `4da52445`), owner-verified on TestFlight 1.1.2 (141), and its story moves to `CLAUDE.md` § Current State.** #726, #729, #730 and #731 have merged too. Every "OPEN" line below is stale on the PR itself and survives only because it still carries a live owner decision. **Re-derive before trusting any line here.**

⚠️ **`list_pull_requests(state=open)` re-derived 2026-09-03 — the open PRs are [#726](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/726) and [#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729) (session 141's).** #722, #723 and #717 have all merged, so every "OPEN" line further down this board is stale on the PR itself and survives only because it still carries a live owner decision. **Re-derive before trusting any line here.**

✅ **MERGED — [#751](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/751), squash `783f1822` — thirty-seven link pins from three creators (session 148, 2026-09-07).** The owner sent 37 Instagram links under three headings; they resolve to **35 distinct shortcodes** and **37 pins ship**, because one post is three pins. **linkPins 1,306 → 1,343 · makers 350 → 353 · `tours` and `places` byte-identical.** Content plus one developer-tooling file (`validate-tours-mirror.py`, which does not ship in the app), so the **auto-merge class** — squash on green CI. **Tanzania is the 59th country**; cities **389 → 404**.
  - ✅ **VERIFIED AGAINST THE SYSTEMS, NOT THE MERGE'S SUCCESS LINE.** All three CI jobs green, including the **authoritative Swift validator**, which agreed with the mirror. The squash was **checked to carry real content** — 2,233 insertions / 3 deletions across 7 files — after #629's empty-commit lesson. On `main`: **353 makers / 1,552 tours / 130 places / 1,343 link pins**, all 37 pins on the three creator rows, **0 link pins wrongly inside `tours`**, and the Zumthor group intact as 3 pins on one hero across Los Angeles / Vals / Mechernich. **All 35 hero URLs live 200, 0 non-200**, re-checked after the parallel gh-pages pushes; exactly **35 new hero URLs for 37 pins**, so the shared-hero case survived the merges.
  - ⚠️ **The gh-pages mirror publish is proved by BLOB IDENTITY, not by the served URL.** Its committed `Tours.json` blob is **byte-identical to `main`'s** (`ccad9922` both sides) while the CDN was still serving the pre-merge copy — the documented propagation lag. **The committed blob, never the served URL, is what says a publish landed.**
  - ✅ **THE SUPABASE SEED LANDED, AND IT WAS RE-MEASURED RATHER THAN ASSUMED.** A reading at 09:25 UTC caught it mid-upsert still serving the pre-merge **1,306** pins; it reached **1,343 at 09:30 UTC**, ~11 minutes after the merge. On the live RPC: **1,343 link pins**, all 37 on the three creator rows (32/4/1), the **Zumthor trio intact as 3 pins on 1 hero**, **0 link pins wrongly inside `tours`**, **0 non-link entries inside `linkPins`**. Session-99 dropped-key check clean — `priceTier` 1,553 with 66 priced, `isPrivate` 375, `country` 1,552, `videoRole` 1,553, `places` 130 — at **200, TTFB 2.0 s / total 2.3 s** on 10.7 MB, which is the materialised snapshot working. ⚠️ **The RPC reads 1,553 tours / 375 makers against the catalogue's 1,552 / 353** (the documented `Zxxx` test tour and upsert-only maker accumulation) — **assert on link-pin counts, never on maker totals**. ⚠️ **The gh-pages CDN took ~17 minutes to converge** (still 1,306 at 09:35, then 1,343) — propagation lag, not a failed publish; the blob identity above is what proved it had landed long before the served URL agreed, and the app reads Supabase first regardless.
  - 🔴 **ONE POST IS THREE PINS, AND THE PASTE IS WHAT SAYS SO.** `DWHSGzlEZSv` was pasted **three times with three different Plus Codes** — Los Angeles, **Vals, Switzerland** and **Mechernich, Germany** — and its caption is a Zumthor round-up naming all three buildings. Shipped as three pins under the documented `@malata.antwerp` scheme (`atlas-tour:link:<sourceURL>#<fragment>`), **sharing ONE hero file**, so 35 files cover 37 pins. ⚠️ **A dedupe check keyed on `sourceURL` alone will read this as a defect.** Its hero is the LACMA frame on all three, which is why three of the batch's five weak heroes are these.
  - 🔴 **TWO REFERENCE GEOCODES WERE WRONG AND BOTH WOULD HAVE SHIPPED.** *"Chuo City Tokyo"* free-text matched **`Tokyo Rokumeikan`, a confectionery in Chuo-ku OSAKA**; *"Venice Italy"* matched **`Venice-Italy`, a restaurant in Graz, AUSTRIA**. A short Plus Code is recovered **relative to its reference**, so a wrong reference silently moves the pin to another country. Both fixed with **structured** Nominatim parameters (`city=`/`state=`/`country=`), never free text.
  - ⚠️ **THE ONE COORDINATE I INFERRED WAS THE ONE THAT NEEDED WORK, and it was verified rather than assumed.** One link carried a bare code (`8FR8GH99+88`) with **no locality at all**; its reverse landed on a different EPFL feature in **1025 Ecublens**, while a **forward** query returns OSM's `Rolex Learning Center` building node at **53.5 m with `city: Lausanne`, postcode 1015**. Ships `Lausanne`. Seven other city disagreements were read by hand and are all correct as shipped.
  - 🔴 **A PRE-EXISTING DEFECT FOUND AND FLAGGED, NOT FIXED — OWNER'S CALL.** The Atlas São Paulo **`Casa de Vidro`** tour sits **841.8 m** from this batch's pin, while OSM's `Instituto Bardi` is **13.4 m** from mine and **833 m** from the tour. **That tour is `geofenced`**, so moving it changes where its audio fires — the documented reason a pin moves and a tour does not.
  - ⚠️ **A REAL BLIND SPOT FOUND IN THE VALIDATOR MIRROR AND CLOSED.** 24 faults injected against this batch's own 37 pins, first run **23/24**: `validate-tours.swift:591` checks a **STOP** title separately from the entry title (line 458) and only the entry one was mirrored. **Read out of the Swift rather than recalled** (the sessions-142/143/145 invented-rule trap), closed and pinned in the mirror's own selftest — **30/30 → 31/31** — then re-run **24/24**, control clean both sides.
  - ⚠️ **A BROKEN VOCABULARY REGEX PRODUCED A FALSE ALARM ON MYSELF.** An ad-hoc check reported *"architect tags used by my pins: []"*; the regex had grabbed the wrong span from `Tag.swift` and returned an **empty** name set, so nothing could match. All 14 architect tags were in fact correct. **The mirror guards against an empty parse; the ad-hoc check did not** — assert `len(names) > 100` before believing a vocabulary verdict.
  - **Ten same-subject pairs flagged, none created** — a place needs its own copy, address, photograph and owner approval. **Nothing is at or over `TourSetMap.maxStacked = 3`**: the only group within 1 m is **Calder Gardens at 0.03 m, two deep**. `check-place-candidates.py` **EXACT unchanged at 22**, NEAR **61 → 70**, the report diff removing nothing.
  - ⚠️ **Five weak heroes flagged, not fixed.** **`Gae Aulenti at the Musée d'Orsay` is the weakest** — a black-and-white archive interior of Olivetti typewriters and a seated man, **neither the museum nor the architect the pin names**. Then the three Zumthor pins sharing the LACMA frame, and the Peggy Guggenheim portrait in a gondola. **No hand re-crop was needed** — `The Stahl House` clips to just *"WHAT"*, but the frame is Shulman's 1960 photograph and the subject's name is nowhere in it, so nothing could be recovered.
  - ⚠️ **Eighteen named architects are absent from the vocabulary**, `Eileen Gray` and `Julia Morgan` most conspicuous — a `Models/Tag.swift` **code** change, deliberately kept out of a content batch. Four omissions are deliberate and verified from the captions (Philip Johnson, Frank Lloyd Wright on Nakashima, Gaudí twice — the Sullivan rule). Catalogue-wide after the change: **743 entries name an architect, 0 missing the shelf tag, 0 of 429 names unused.**
✅ **MERGED AND LIVE — [#746](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/746), squash `4936b48b` — the `@poche_space` pin moves onto the Gilder Center (session 147, 2026-09-07).** Owner: *"OK move the poche space to the gilder center"* — the question #744 flagged and left open. **Gilder Center 3 → 4 members · AMNH 6 → 5.** Content plus one line of developer tooling, so the **auto-merge class**: squash on green. `tours`, `makers` and every other place **byte-identical**; **exactly one pin moved, in exactly its four coordinate fields**; diff **7 insertions / 7 deletions**. No Swift, no SQL, no gh-pages push, no build. ⚠️ **It also carries the docs correction the PR was originally opened for** (#744 recorded merged and verified live, and *"2,830 single-stop entries"* corrected to **2,758** in five files — 2,830 is the total, 72 are walks). ⚠️ **Overlap check before merging: [#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743) also edits `places` and one link pin** (Eastern State's third member) — a different place and a different pin, so no logical overlap, but whichever merges second may need `Tours.json` re-resolved the documented way: **take `main`'s file and re-run the idempotent assembler, never hand-resolve.**
  - 🔴 **A REAL BLIND SPOT CLOSED IN `validate-tours-mirror.py`, found by injection and CHECKED AGAINST THE SWIFT BEFORE BEING CALLED ONE.** `validate-tours.swift:553-554` errors when a `kind: "link"` entry's stop is not `manual`; the mirror checked nowhere, so flipping this pin to `geofenced` would have passed locally and failed CI. Added and **pinned in the mirror's own selftest** (30 → **31 cases**). ⚠️ **Sessions 142, 143 and 145 each shipped a "blind spot" that was a rule they had invented** — this one was read in the Swift first, and the catalogue still reads **0 errors**, which independently proves **no existing link pin is geofenced**.
  - ✅ **The centroid-drift blind spot the #744 entry records as still-blind is now CLOSED by [#745](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/745)** — confirmed **by injection (CAUGHT)**, not by reading their PR body.
  - ⚠️ **FLAGGED, NOT ACTED ON: the moved pin carries `Museum, Architecture` and no architect tag**, while its own text names Studio Gang repeatedly and its three new place-mates all carry **`Jeanne Gang` + `Designed by a Master`**. **Pre-existing on `main`**; the owner asked for a move, not a retag. One line each closes it.
    - ✅ **CLOSED by [#752](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/752), squash `bb49eedc`** (owner: *"Add the architect tag to the poche space pin"*) — the pin now carries `Jeanne Gang` **alongside** `Designed by a Master`, so the four Gilder Center members share architect shelves. ⚠️ It still lacks the `Contemporary` styleEra tag its three place-mates carry — one line, deliberately left as scope its instruction did not cover.
  - ✅ **AMNH's hero is safe, checked not assumed** — `AMNH__Introduction_2.webp` is a third photograph from the Atlas *Four Facades* walk, which remains a member, not the departing pin's. Borrowed-hero count re-derived, **still 54 of 130**.

✅ **MERGED AND LIVE — [#745](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/745), squash `45914d1f`, twenty-eight link pins across fourteen countries (session 147, 2026-09-07).** All three CI jobs green on the merge head `08342e6b`; the squash was **checked against `main` for real content** (the #629 empty-commit lesson) at **1,683 insertions across 7 files**. ✅ **Verified against the LIVE systems, not the merge's success line:** the Supabase RPC — the source the app reads **first** — serves **`linkPins` 1,306 / `places` 130** with **0 pins wrongly inside `tours`**, and the gh-pages mirror serves the same at **1,552 / 1,306 / 350 / 130**. Session-99 dropped-key check clean on that payload (`priceTier` 1,553 with 66 priced, `isPrivate` 372, `country` 1,552, `videoRole` 1,553). ⚠️ **The RPC reads 1,553 tours / 372 makers against the catalogue's 1,552 / 350** — the documented `Zxxx` test tour and upsert-only maker accumulation; **assert on link-pin counts, never on maker totals.** 29 owner-sent lines under three loose headings → **28 distinct posts** (one TikTok pasted twice) → **28 shipped, 0 blocked, 0 already pinned**. **linkPins 1,278 → 1,306 · makers 346 → 350 · `tours` and `places` byte-identical.** Content plus one developer-tooling file (`validate-tours-mirror.py`, which does not ship in the app), so the **auto-merge class** — squash on green CI. 🎉 **Eleven new countries, the largest expansion any batch has produced** (previous record three): Turkmenistan · Madagascar · Yemen · Peru · Jordan · Uzbekistan · Turkey · Afghanistan · Singapore · Tunisia · Mongolia, taking the catalogue **47 → 58 countries and 367 → 389 cities**.
  - 🔴 **OWNER DECISION OWED — GRIFFITH OBSERVATORY IS NOW EXACTLY AT `TourSetMap.maxStacked = 3` WITH NO HEADROOM.** The existing **place** (2 members → one capsule) plus this batch's two new coincident pins make **3 markers**; a fourth Griffith link would put one permanently out of reach, invisibly. ⚠️ **Measured, not assumed:** the new pins sit **5.4 m** from the place's coordinate — the CalAcademy rounding artifact (the Plus Code decodes at 7 decimals, the place stores fewer) — so they are **not** members and the checker reports them as their own group. **Recommendation: join both to the existing place** — one line each, taking it **2 → 4 members** and collapsing all four into one capsule. 🔴 **Nothing was nudged onto the place's coordinate here** — that manufactures an EXACT group with no place behind it. ⚠️ Two milder groups need no action: **Cook County courthouse ×2** and **Fort Carroll ×2** are two deep, inside the cap; and the **Flatiron** pin sits **19.5 m** from the Atlas tour — not coincident, so not a candidate under the exact rule.
  - 🔴 **TWO COORDINATES LOOKED WRONG AND WERE RIGHT, and I nearly moved both.** I had the baobabs 4.8 km off against `Allée des Baobabs` — a **bounded** search returns **`Baobabs Amoureux` at 26 m**, exactly what the caption names. **Distance from the OBVIOUS landmark proves nothing when the caption names a different one.** And OSM's `Skylodge Adventure Suites` sits **14 km** from the Starlodge point while that caption says outright they are separate properties. A third was **relabelled rather than moved** (the `Kakslauttanen` code lands on the **Aurora Queen Resort**, ~20 km away in the same municipality). ⚠️ **One coordinate WAS wrong and moved 69 km** — the Uros floating-islands pin sat in open water and reverse-geocoded to a bare `Perú` at zoom 12 **and** 14, the signature of a point that has landed on nothing.
  - ⚠️ **The heading was loose for the fifth batch running** — `Da-egbhlU76` sits in the "Iamlamlam" block and is `@travpholer`. **Read the payload, not the heading.**
  - 🔴 **Three real blind spots found in the validator mirror and closed — and a fourth that was a rule I INVENTED.** 24 faults injected against this batch's own 28 pins, first run **20/24**; **reading `validate-tours.swift` rather than recalling it** (sessions 142, 143 and 145 each shipped an invented rule) found three genuine gaps — **empty title** (line 458), **a link pin with a nonzero `totalDurationSeconds`** (line 565, checked against **0 exactly**) and **centroid drift** (lines 683-685) — while `city: ""` **is not a rule at all** (`let city: String?`, no non-empty check). Real score **20 of 23**. ⚠️ The centroid rule is a **WARNING**, so the mirror's selftest needed `warns=True` (the session-141 bug): **27/27 → 30/30**, then **24/24 on the batch, control clean both sides**.
  - **Verification:** mirror **0 errors, 0 warnings across 1,552 tours + 1,306 pins + 130 places** at 479 tags, exit code read directly; **all 28 heroes opened and read against their captions, zero wrong subjects**; **four hand re-crops** through a mirror **self-checked against `render_hero` byte-for-byte at vfocus 0.5 (28 identical)**; **0** duplicate ids / live-id collisions / already-pinned sourceURLs / byte-duplicate heroes; **0 filename collisions against 7,098 gh-pages `images/` paths**, the listing asserted >1,000 first; `Tours.json` **byte-stable before AND after editing**, diff **1,301 / 0**, purely additive; seed clean at **350 / 2,858 / 3,230 / 130**, **0 `images//`**; gh-pages `21d82cd` tree diff **exactly 28 additions, 0 deletions, nothing outside `images/`**, deploy `success`, then **all 28 live URLs hash-verified — 28 ok, 0 mismatch, 0 non-200**; 🔴 **`check-image-duplicates.py --pins` run AFTER the deploy** — **`OK`** over **1,301 images**, shared-URL half **0 errors / 208 documented reuses**, identical to the baseline.
  - ⚠️ **`main` moved TWICE mid-session** — [#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742) landed the catalog materialisation (no `Tours.json` change, so the branch fast-forwarded), then [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) merged **while this PR's own CI was green and running**, making the Gilder Center a place (places 129 → 130) and moving two pins, so `Tours.json` genuinely conflicted. Resolved the documented way — **main's file taken wholesale and the idempotent assembler re-run on it, never hand-resolved** — with **overlap re-verified at 0 on every axis** and every check re-run on the merged base (checker **19 EXACT → 22 / 59 NEAR → 62**, the same +3/+3 delta, still removing nothing). ⚠️ **#744 also claimed `archive/HANDOFF-260907.md`**, so this handoff is **`-2`**, and **both sides had edited the Key-facts counts** — merged into one line rather than left duplicated. ✅ **A content merge needs nothing extra under the new scheme, verified rather than assumed** — the regenerated seed SQL calls `refresh_catalog_snapshot()` as its last act.
✅ **MERGED — [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) (squash `f6c1815e`), the Gilder Center becomes a place (session 147, 2026-09-07).** All three CI jobs green; the squash **checked to carry real content** (372 insertions / 10 deletions across 6 files) after #629's empty-commit lesson; then **verified against the LIVE systems rather than the merge's success line** — the Supabase RPC and the gh-pages mirror each serve **130 places** with The Gilder Center present, its **3 members all on the place coordinate**, **0** members off their place coordinate catalogue-wide and **0** link pins wrongly inside `tours`. 🔴 **The RPC answered in 4.7 s, which is the reading that matters: [#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742)'s SQL is still unpasted.** ⚠️ **SUPERSEDED — the owner pasted it at 21:44 UTC the same evening and it is APPLIED; nothing owed.** Re-probed before merging: `catalog_snapshot_age()` **200**, `get_catalog()` **200 on 4 of 4** against 3 of 3 500s an hour earlier. ⚠️ **Fixed, not sub-second** — total 1.2–4.2 s but **TTFB 1.7–3.7 s with the 10.6 MB body in the remaining 0.3–0.5 s**, so the time is in the query and the *"seconds means not served"* criterion is too crude alone. 🔴 **A probe is a measurement with a timestamp, not a durable fact.** It returned 200 first try — and a pass/fail count is the wrong signal, because a 33%-failure endpoint comes back clean often enough to be closed as *"cannot reproduce"*. **Latency is the signal**, and `scripts/check-catalog-keys.py` corroborates it independently: *"catalog snapshot: not in use (built per request)"*. Its story now lives in `CLAUDE.md` § Current State. Owner: *"MAKE GILDER CENTER A PLACE. DONT WORRY ABOUT WEAK HEROES."* **Places 129 → 130** — the last stack-cap finding the Studio Gang batch raised, closed. Content only, so the **auto-merge class**: squash on green. `tours` and `makers` **byte-identical**, the 129 existing places unchanged as a prefix, **exactly 2 link pins moved in exactly their four coordinate fields each** — every one of the diff's 8 deletions is a coordinate line. Diff **24 insertions / 8 deletions**. No Swift, no SQL, no gh-pages push, no build. Detail: `archive/HANDOFF-260907.md`.
  - ✅ **FOLLOW-UP, same session — the `@poche_space` pin moved onto it (owner: *"OK move the poche space to the gilder center"*), open as [#746](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/746). Gilder 3 → 4 members · AMNH 6 → 5.** The question the entry above flagged and left open, answered. **⚠️ It was flagged rather than done because it shrinks a place another session built** — a session can move a pin onto a place it plainly belongs to; it cannot decide to take a member off a different one. AMNH stays well clear of the two-member floor. **The pin moves, never the tour:** asserted `manual` before anything was written (the builder refuses otherwise), moved **176.3 m**; nothing else moved. Diff **7 insertions / 7 deletions** — two `tourIds` arrays and the pin's four coordinate fields. ✅ **AMNH's hero is safe, checked not assumed** — `AMNH__Introduction_2.webp` is a third photograph from the Atlas walk, which remains a member; borrowed-hero count re-derived, **still 54 of 130**. 🔴 **A real blind spot closed in `validate-tours-mirror.py`, found by injection and CHECKED AGAINST THE SWIFT FIRST** — `validate-tours.swift:553-554` errors when a `kind: "link"` stop is not `manual` and the mirror checked nowhere; added and pinned in its selftest (**30 → 31**), and the catalogue still reads 0 errors, which proves no existing link pin is geofenced. ✅ **The centroid-drift blind spot recorded above as open is now CLOSED by [#745](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/745)** — confirmed by injection (CAUGHT), not by reading their PR body. ⚠️ **FLAGGED, NOT ACTED ON: the moved pin carries `Museum, Architecture` and no architect tag** while its three new place-mates all carry `Jeanne Gang` + `Designed by a Master` — **pre-existing on `main`**, and the owner asked for a move, not a retag. **Verification:** mirror **31/31 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,306 pins + 130 places**; **18 faults injected against THIS move — 18/18 caught, control clean both sides**; 🎉 **`check-place-candidates.py` BYTE-IDENTICAL before and after at 22 EXACT / 61 NEAR** (correct — the pin moved between two coordinates the checker already ignores because both carry a place); seed clean at **350 / 2,858 / 3,230 / 130** with **0 `images//`**. ⚠️ `check-image-duplicates.py` deliberately NOT run and that is not a gap — no image URL changed, asserted.
  - **🔴 THE CHECKER UNDER-REPORTED THE CAP, WHICH IS WHY THIS SAT UNBUILT.** Three markers **at most 3.44 cm apart** — one point — **exactly at `TourSetMap.maxStacked = 3` with no headroom**; all three are link pins by **different creators**, so the cap bites on the Home map and every place and list map rather than on a creator page. ⚠️ `check-place-candidates.py` reported it as an **EXACT pair plus a separate NEAR pair, never a group of three**, because the third pin differs in the **7th decimal** (the CalAcademy rounding artifact). That is why resolving it moves two tiers at once.
  - **🔴 A BUG THE MIRROR CANNOT SEE, CAUGHT BY READING THE DIFF.** The assembler's first run wrote **`centerLatitude` / `centerLongitude`** — fields that **do not exist on `Tour`** (`Models/Tour.swift:259`) — and left the real `centroidLatitude` / `centroidLongitude` **stale at the old coordinate**. **`validate-tours-mirror.py` passed it at 0 errors**; centroid-vs-stop agreement is a documented mirror blind spot that **`validate-tours.swift` DOES check**, so it would very likely have failed CI. The assembler now asserts **no member gains or loses a top-level key** and **every centroid mirrors its stop**, and because the fault suite confirms the mirror is still blind to it, the property is **asserted directly** — 0 drift on the members and **0 catalogue-wide across 2,758 single-stop entries** (⚠️ 2,830 is the TOTAL entry count; the other 72 are walks, where a centroid legitimately differs from stop 0).
  - **✅ ONE MEMBER DID NOT MOVE AT ALL.** The anchor is **OSM node `10172954431`** (forward geocode **0.0 m**; the reverse names the building exactly) and all three markers had independently converged on it. ⚠️ **The address is `200 Central Park West`, and `415 Columbus Avenue` was recollection** — unbounded, OSM returns three hits **24 km, 85 km and 483 km** away; probing the Columbus side, OSM assigns 200 CPW to the whole campus at every probe.
  - **⚠️ SWEPT 400 m; both things in range are correctly excluded.** The **AMNH cluster at 176.1 m** — ✅ **the owner ruled in session 140 that the Gilder Center stays separate** (*"Gilder center keep separate"*); **closed**, and a future audit will flag it again. ✅ **RESOLVED 2026-09-07 — the owner moved it** (*"OK move the poche space to the gilder center"*): the `@poche_space` pin `Poché - Studio Gang | episode 2 of 3` is substantively about the Gilder Center (its whole `longDescription`, and its hero file is literally `amnh-gilder-center_hero.webp`) yet sat at the **AMNH** coordinate as one of that place's six members. **Gilder 3 → 4, AMNH 6 → 5.** See the follow-up entry below; **do not re-raise it.**
  - **⚠️ The hero is borrowed and structural** (every member is a link pin with an empty gallery; no Atlas tour here) — **do not go sourcing a replacement**; borrowed-hero count re-derived **54 of 130**. All three candidates rendered and looked at; ⚠️ **stated trade-off** — `@archimarathon`'s is the finer picture, rejected only for a clipped subtitle, and **none of the three is an exterior**. ✅ **Weak heroes CLOSED by the owner.**
  - **⚠️ The two members disagree on the opening date and the copy takes neither side blindly** — verified externally as **4 May 2023**; February is a countdown to a slipped opening and is **repeated nowhere** (the Schweizer convention).
  - **Verification:** mirror **27/27 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,278 pins + 130 places**, exit code read **directly**; 🔴 **15 place-layer faults injected against THIS place — 14 caught, control clean both sides**, the one miss being the centroid blind spot **deliberately included to confirm it is still blind** and asserted directly instead; 🎉 **`check-place-candidates.py` EXACT 20 → 19, NEAR 60 → 59**, the report diff proving it removes **exactly the Gilder pair plus the 0 m NEAR pair and adds nothing**; seed clean at **346 / 2,830 / 3,202 / 130** with **0 `images//`**; hero live **200**, hash-matched. ⚠️ **Nothing compiled locally — CI is the only compile check.**
  - **⚠️ `main` MOVED MID-SESSION and every check was re-run on the moved base.** #742 merged while this was being verified, touching **9 files including `backend/seed_from_toursjson.py` and every doc file this session had to write** — but **not `Tours.json`**, whose baseline is **byte-identical on both bases**, so the build carried over with nothing to redo.

🟡 **OPEN — [#748](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/748), the Eastern State handoff and a correction to yesterday's stale note (session 146 continued, 2026-09-07).** **Docs only — no catalogue change, no Swift, no SQL — so the auto-merge class**: squash on green. Writes `archive/HANDOFF-260907-3.md` (⚠️ `-3` because two parallel sessions had already claimed `-260907` and `-260907-2`), indexes it, and flips #743 on this board. 🔴 **It also corrects `archive/HANDOFF-260906.md`, whose "Still open" list called Eastern State a place CANDIDATE** — left there it would have told a future session to build a place that has existed since the session-144 batch. ⚠️ **The original wording is kept inline rather than deleted, because the measurement in it was right and only the conclusion drawn from it was wrong:** *"3.7 m from the existing two-member place"* describes a pin **outside** a place, not a place waiting to be made.

  - ✅ **Carries the live verification of #743** — see the merged entry directly below.
  - ⚠️ **Two process traps recorded:** **`$SCRATCH` is not set in this container**, so `"$SCRATCH/foo.sh"` resolves to **`/foo.sh`** — eight files and directories were created at the **filesystem root** before this was noticed, and removed; **echo the variable before using it in a path.** And **two readers on one file give a number from one moment beside a body from another** — a foreground read of a background poll's output reported `HTTP 200 … 10649683 bytes` next to a **100-byte error body**.

✅ **MERGED as [#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743) (squash `b4d412ef`) — Eastern State Penitentiary gains its third member (session 146 continued, 2026-09-07).** Verified to carry real content — **35 insertions / 10 deletions across exactly the 3 expected files**, `Tours.json` at 6/5 (the #629 empty-commit lesson). Owner: *"eastern state already has a place. move 'inside the abandoned eastern…' into that place"*. **They were right, and the standing note calling it a place *candidate* was wrong** — the place has existed with two members since the session-144 batch; only the third pin was outside it. `Inside the Abandoned Eastern State Penitentiary` is now a member; **places stay 130**, `tours` and `makers` **byte-identical**, and **exactly one pin changed, in exactly its four coordinate fields**. Diff **6 insertions / 5 deletions**. Content only — no Swift, no SQL, no gh-pages push, no build. ✅ **Verified live on the Supabase RPC — the source the app reads FIRST — not on the merge's success line:** the place serves **3 members**, all three exactly on its coordinate and all three `manual`; session-99 dropped-key check clean on the same payload (`priceTier` 1553 / 66 priced, `isPrivate` 372, `country` 1552, `videoRole` 1553, **0 link pins wrongly inside `tours`**, 0 places under two members, 0 tours claimed twice). ⚠️ The RPC reads **1553 tours / 372 makers** against the catalogue's 1552 / 350 — the documented `Zxxx` test tour and upsert-only maker accumulation; **assert on place membership, never on maker totals.** Detail: `archive/HANDOFF-260907-3.md`.
  - **The pin moved 3.78 m; the place did not.** All three members are `manual` link pins, so no geofence is disturbed — but the builder **asserts `manual` before relocating anything and refuses otherwise**, so a future edit cannot get this backwards silently. The 3.8 m gap is the documented **Plus Code cell-centre artifact** (the code decodes to a cell centre at 7 decimals), which is also why it never reached EXACT and showed only as a 4 m NEAR pair — invisible to the checker, and reachable only because it was flagged by hand.
  - ⚠️ **SWEPT 400 m AROUND THE SITE rather than trusting the flagged pair** (the session-131 lesson). **Nothing else is within 400 m at all** — the three pins are the whole story, so unlike Alwyn Court there is **no deliberate exclusion to record.**
  - ⚠️ **The place hero is untouched and is NOT borrowed** — it is a sourced photograph (`eastern-state-penitentiary-place_hero.webp`), so adding a member changes nothing about it. **Borrowed-hero counts are unaffected.**
  - **Verification.** `Tours.json` **byte-stable under a Python re-dump before AND after**; `tours`/`makers` asserted byte-identical; **exactly one place changed, in `tourIds` alone**, with the two existing members asserted unchanged as a prefix; **all three members asserted to sit exactly on the place coordinate**; **every image URL in the catalogue asserted unchanged**. Mirror **self-tested 30/30 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,306 pins + 130 places**, exit code read **directly, not through a pipe**. ⚠️ **20 place-layer faults injected against THIS place specifically — 20/20 caught, control clean before and after.** 🎉 **`check-place-candidates.py` NEAR 62 → 61 with EXACT unchanged at 22**, and the report diff proves it removes **exactly the Eastern State pair and adds nothing** — no coincident group was manufactured; ⚠️ it still exits 1 on the 22 belonging to other batches, so **a clean exit is not the expected state today.** Seed clean at **350 / 2,858 / 3,230 / 130**; **0 `images//`** in the catalogue *or* the SQL. ⚠️ **`check-image-duplicates.py` was deliberately NOT run and that is not a gap** — no image was added and no image URL changed, both asserted.
  - 🔴 **A STALE SCRATCH FILE NEARLY REPORTED A FALSE PASS, AND THE COUNT IS WHAT CAUGHT IT.** A `grep` guard in a `&&` chain failed, so the fault suite **never ran** — and `cat` printed a **two-day-old** output file from session 145 that read *"22/22 faults caught"*. It was caught only because 22 did not match this suite's 20. **Write a check's output to a UNIQUE path and confirm its timestamp**, or a `&&` short-circuit hands you someone else's pass. Re-run properly: **20/20, exit 0, written the same second.**
  - ⚠️ **ONE "MISS" WAS A RULE I INVENTED, caught on myself — the fourth session running.** The suite first reported a miss on *"centroid disagrees with its stop"*. Read directly rather than recalled, `validate-tours.swift:676-687` makes that a **warning with ~1 km of slop**, and the fault had moved the centroid **73 m** — so the real validator would not flag it either. **It is not a mirror blind spot.** Resized past the slop, it is caught. **Before calling a mirror miss a blind spot, read the Swift rule.**

✅ **MERGED AND NOW LIVE — [#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742), squash `9eaabdd1` — the catalog RPC was failing a third of the time (session 146, 2026-09-06).** ✅ **The owner pasted `backend/catalog_snapshot.sql` at 21:44 UTC on 2026-09-07 — re-probed directly before merging #746, not inherited from this board:** `catalog_snapshot_age()` returns **200 with a timestamp**, `scripts/check-catalog-keys.py`'s own verdict flipped from *"not in use (built per request)"* to *"catalog snapshot last refreshed: …"*, and **`get_catalog()` answered 200 on 4 of 4** spaced calls against **3 of 3 500s** an hour earlier. ⚠️ **It is fixed, not sub-second, and the difference matters when judging it:** total is 1.2–4.2 s, but **TTFB is 1.7–3.7 s while the whole 10.6 MB body transfers in the remaining 0.3–0.5 s** — the time is in the query, not the download, so session 146's *"seconds means the snapshot is not being served"* criterion is too crude to use alone. **Split TTFB from total.** 🔴 **AND "THE TIMEOUTS ARE GONE" IS AN OVERSTATEMENT — CORRECTED 2026-09-08 after #752.** Re-measured over a longer window: **11 ok / 1 failed of 12** spaced calls, plus 1 more failure in a separate 7-call pass; **a second session sampled 20 more the same morning and saw 3 fail**. Together **5 of 39 return `500 / 57014` — roughly 1 call in 8**, against session 146's pre-fix **4 in 12**. A large improvement (~33% → ~13%), **not** a full fix. ⚠️ **The snapshot IS in use while this happens** (`catalog_snapshot_age()` 200 with a fresh timestamp in the same pass), so a further timeout is **not** evidence the paste was lost — the single-row lookup of a 10.6 MB `jsonb` is itself near the anon statement timeout. **Report the failure rate, never "gone".** ⚠️ **This also supersedes [#747](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/747), which landed on `main` hours earlier saying the fix was *"NOT live … has not been run"* — and #747 was NOT wrong when it was written.** It measured `catalog_snapshot_age()` and `get_catalog_built()` both at **404 `PGRST202`**; they now return **200** and **500**, and ⚠️ **that 500 is the migration WORKING rather than failing** — the slow builder now runs once per seed and nothing serves it to a phone. **The durable lesson is that an owner-owed item can be cleared while a session is mid-flight, so re-measure before repeating "still owed" from this board.** 🔴 **The stale text below is left as the record of a probe that was true when taken** — this branch would have overwritten the parallel correction in [#748](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/748) with it, which is exactly what § READ FIRST exists to prevent. Squash **verified to carry real content — 671 insertions across 9 files** (the #629 empty-commit lesson), and all four checks were green. 🔴 **A NOTE ON THIS BOARD SAYING *"session 147 confirmed the content path independently — a content merge needs nothing extra"* WAS TRUE IN LETTER AND THE WRONG THING TO TAKE COMFORT FROM.** The seed's refresh call is guarded by `to_regprocedure('public.refresh_catalog_snapshot()')`, so with the paste unapplied the guard is false: the seed **skips** the refresh, raises a notice and still finishes green. **A guarded no-op is indistinguishable from a success from the outside — ask `catalog_snapshot_age()`, never a green seed job.** Proven on the live database after #745 rather than inferred: `catalog_snapshot_age()` and `get_catalog_built()` both **404 `PGRST202`**, and the RPC still returned **`500 / 57014 statement timeout` on 2 of 5 spaced calls**. See § SQL pastes owed — the ordering gate has cleared and it is safe to paste now. `get_catalog()` — the source the app reads **first** — returns `500 / 57014 statement timeout` on **4 calls in 12**, sampled long after any seed. Successes 2.2–4.9s, failures 3.5–5.0s: the query is **sitting on** the anon role's statement timeout, so variance decides each call. It rebuilds ~11 MB of JSON per request (a correlated subquery per tour, then `split_link_pins.sql` explodes the finished blob and re-aggregates it **twice**), and the payload is **identical for every caller** — verified, not assumed. `backend/catalog_snapshot.sql` renames the builder aside (the `places.sql` rename-and-wrap precedent, so nothing is retyped) and makes `get_catalog()` a single-row lookup. **Backend + tooling only — no Swift, no `Tours.json`, no build.**
  - 🔴 **OWNER STEP, AND THE ORDER MATTERS: merge first, paste second.** The seed change is guarded by `to_regprocedure`, so merging before the SQL does nothing. **The reverse is not safe** — applying the SQL while the old seed is live would upsert rows and never refresh, leaving every phone on a stale catalogue **with nothing erroring**. See § SQL pastes owed.
  - 🔴 **IT ALSO FIXES A TORN READ, which is the better argument.** Observed live at 03:52: the RPC served **`tours` 1553 (new) alongside `places` 121 (old)** mid-seed. The builder is `stable`, so it is consistent *within* one statement — but the seed commits progressively across many. Refreshed as the seed's last act, MVCC keeps every reader on the previous **complete** catalogue until commit.
  - ⚠️ **TWO DESIGN POINTS ARE FORCED, NOT PREFERENCES.** `refresh_catalog_snapshot()` is **SECURITY INVOKER** — Postgres refuses outright (*"cannot set parameter `role` within security-definer function"*), so the role switch and definer are mutually exclusive and the switch is worth more; **found by running it, not by reading**. And the builder runs as **`anon`**, so the snapshot is exactly what an anonymous reader gets: narrower than or equal to any signed-in view, never wider.
  - ⚠️ **AFTER THIS, A HAND EDIT IN THE SQL EDITOR IS INVISIBLE until you run `select public.refresh_catalog_snapshot();`** — now Automation Rule **11b**. Normal content merges handle it themselves.
  - **Verification:** `backend/test-migrations.sh` **4 applied, idempotent, all catalog keys and places intact** against a real throwaway Postgres 16; 🔴 **6 faults injected, 6/6 caught, control clean before and after**, each mutation's anchor asserted to appear **exactly once** so a fault that fails to apply cannot pass; the two security-critical assertions checked **individually**, with a **negative control** on the leak test so it proves the role rather than passing for free; `check-catalog-keys.py --selftest` **13/13** (was 8 — the file audit had **no coverage at all**); seed clean at **346 / 2,830 / 3,202 / 129**, **0 `images//`**. ⚠️ **The fixture never modelled `anon`** — no grants, no RLS, no unpublished row — so it described a database that could not have worked; fixed, and used to prove the security property.
  - ⚠️ **MY FIRST TWO READINGS WERE EACH ONE SAMPLE OF A FLAPPING SIGNAL** — reported first as "down", then as "recovered". Neither was right. **Sample a flapping endpoint before characterising it.**

✅ **MERGED as [#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740), squash `62b662b4` — four places (session 145, 2026-09-05).** All four checks green on the rebuilt head; content only, so the auto-merge class. Owner: *"11 hoyt is Brooklyn. Make places for all suggested"*. **Places 125 → 129** — **Faena Hotel Miami Beach** (4 members), **The Surf Club** (3), **Patch of Heaven Sanctuary** (2), **Arkansas Museum of Fine Arts** (4) — closing every stack-cap finding the two batches below raised. A **pure addition**: `tours`, `makers` and `linkPins` byte-identical, the 125 existing places unchanged as a prefix, and **nothing moved** (all 13 members were already exactly coincident and every one is `manual`, asserted first). Diff **65 insertions / 0 deletions**. Content only — no Swift, no SQL, no gh-pages push, no build.
  - ⚠️ **SWEPT 400 m AROUND EACH SITE rather than trusting the checker's group** — and here the group genuinely was the whole story all four times; the nearest non-member is 1.3 km / 3.0 km / 4.4 km / 469 km away, so **there is no deliberate exclusion to record.**
  - 🔴 **ALL FOUR HEROES ARE BORROWED AND THAT IS STRUCTURAL** — every one of the 13 members is a link pin with an empty gallery and there is **no Atlas tour at any of the four sites**, so no third photograph exists (the closed Waterlooplein case). **Do not go sourcing replacements.** All 13 candidates were rendered and looked at; borrowed-hero count re-derived **53 of 129**. ⚠️ **The Faena pick is the closest call** — `@travelwithlivii`'s frame names the hotel outright with the FAENA wordmark and was rejected only because the creator fills its centre; one line swaps it.
  - ✅ **Every anchor confirmed by geocoding**, and the Surf Club's address took **both directions**: its reverse lands on `The Surf Club South` at 9001 Collins (a neighbouring building in the same complex) while the forward returns `Four Seasons Hotel at The Surf Club, 9011 Collins Avenue` at **0.0 m** — the number the Lido pin's own caption gives, and the one that ships. ⚠️ **Patch of Heaven forward-geocodes to NOTHING** (OSM maps no sanctuary feature), so its address is the venue's own, corroborated by the reverse landing on the 21900 SW 157th Avenue address point.
  - **Verification:** mirror **27/27 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,278 pins + 129 places**; ⚠️ **53 place-layer faults injected against THESE FOUR PLACES specifically — 53 caught, control clean before and after**; 🎉 **`check-place-candidates.py` EXACT 24 → 20, NEAR unchanged at 60**, the diff proving it fell by exactly the four groups resolved and gained nothing; seed clean at **346 / 2,830 / 3,202 / 129** with **0 `images//`**; all four hero URLs live **200** and hash-verified against the bytes actually looked at.
  - ⚠️ **`main` MOVED UNDER THIS BRANCH and that is why CI had never run on [#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740) — a conflicted PR triggers no checks at all** (the session-34 trap). [#737](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/737) landed 41 pins and [#739](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/739) built four **different** places. Resolved the documented way — **main’s `Tours.json` taken wholesale and the idempotent assembler re-run on it, never hand-resolved** — and it ran clean, every precondition still holding. The two place sets are **disjoint with 0 member overlap**, so 121 + 4 + 4 = **129**. ⚠️ The handoff renumbered **`-3` → `-5`**; `-2`, `-3` and `-4` were all taken by other sessions the same day.

✅ **MERGED as [#739](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/739), squash `ee17384c` — four places for the sites at the stack cap (session 146, 2026-09-05).** Owner: *"Make the places for the four sites."* **Alcatraz · Hoover Dam · Fort Jefferson · the Leaning Tower of Niles**, each three coincident markers against `TourSetMap.maxStacked = 3` with no headroom. **Places 121 → 125**; content only, so the auto-merge class — squash on green CI. `tours` and `makers` **byte-identical**; exactly **3 link pins moved** (Alcatraz, 5.7 m onto the geofenced Atlas tour, which joins as a fourth member — **the pin moves, never the tour**). ⚠️ **Three heroes are borrowed and it is structural** (no third photograph of those sites exists anywhere in the catalogue — proved, not assumed); **do not go sourcing replacements.** Verification: **49 place-layer faults injected against these four — 49/49 caught**; mirror **0 errors, 0 warnings across 1,552 tours + 1,278 pins + 125 places**; **`check-place-candidates.py` EXACT 28 → 24, NEAR 63 → 60**, adding nothing. Detail: `archive/HANDOFF-260905-4.md`.

✅ **MERGED as [#737](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/737) — 41 link pins from TikTok `@itshistoryonair` (session 144, 2026-09-05).** Opened and merged on owner instruction (*"Open pr and merge when ready"*); content only, so the auto-merge class. ⚠️ **`main` moved TWICE while it sat open** — [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738) landed 36 pins and 17 makers, then a docs follow-up — so the `Tours.json` conflict was resolved the documented way: **main's file taken wholesale and the idempotent assembler re-run on it, never hand-resolved.** Overlap between the two batches was **0 on sourceURLs, tour ids, stop ids and hero filenames.** Merged reality: **1,278 pins · 346 makers · 1,552 tours · 121 places.** ⚠️ **The handoff renumbered TWICE on add/add collisions** (`-260905` and `-2` were both taken by two other sessions the same day) and is `archive/HANDOFF-260905-3.md`.
  - 🔴 **OWNER DECISION OWED — SIX SITES SIT EXACTLY AT `TourSetMap.maxStacked = 3`, AND ALL 41 PINS ARE ONE CREATOR**, so they stack on that creator's own maker page. **Three deep with NO headroom: Alcatraz · Hoover Dam · Fort Jefferson · the Leaning Tower of Niles.** Two deep with one spare: Paris Catacombs, Washington Monument, Ellis Island, Seven Mile Bridge, Alang. **Nothing is unreachable today**, but a fourth link at any of the four would put one marker permanently out of reach, invisibly. **Recommendation: make places for the four.** ⚠️ **A fifth, Eastern State, is a different shape** — the new pin sits **3.7 m** from the existing two-member place, so it is **not coincident**, never reaches EXACT, and joining it as a third member is a deliberate one-line move of a `manual` pin (the Guggenheim / ROM Crystal precedent). **Nothing was created here.** ✅ **DONE 2026-09-07 on owner instruction — the pin moved 3.78 m and the place has three members.** ⚠️ **Eastern State was never a place *candidate*; the place already existed and only the third pin sat outside it. A later note calling it a candidate was wrong.**
  - ⚠️ **A CORRECTION THIS SESSION MADE ON ITSELF: Alcatraz is *at* the cap, not past it.** An early read called it 4 markers deep; measured, the three new pins are exactly coincident and the Atlas SFO tour is **5.7 m away** — a separate marker, the documented CalAcademy rounding artifact (Plus Code at 7 decimals vs the tour's 4). Same shape at the Paris Catacombs and the Eiffel Tower. **Measure the group before reporting its depth.**
  - 🔴 **OWNER DECISION OWED — one hero is unusable: `Why the Cliff House Was Built` is a completely blurred, unreadable smear.** Not a crop artifact; the source thumbnail is out of focus, and a link pin re-hosts only the thumbnail, so keep-or-pull is the whole choice. Four others are weak and flagged: `George Washington's Legacy` (a **portrait painting**, not the monument), `The Pyramid of Rapa`, `The Most Valuable Ships at Alang`, `What's Inside the Paris Catacombs`. ⚠️ **`The Oldest Photograph of Stonehenge` is ALSO historical and is CORRECT** — the post's subject *is* that photograph.
  - ⚠️ **`check-place-candidates.py` goes 12 EXACT → 21 and 53 NEAR → 63, and the report diff proves it REMOVES NOTHING** — no coincident group was manufactured and nothing was nudged apart. Verification: mirror **24/24 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,242 pins + 121 places** at 479 tags, **exit code read directly**; **22 faults injected against this batch's own 41 pins — 22/22 caught, control clean both sides**, counting **errors AND warnings** and injecting **in memory via `check()`**, with the new-pin ids **derived from the diff against `HEAD`**. Seed clean at **329 / 2,794 / 3,166 / 121**, **0 `images//`**.

✅ **MERGED AND LIVE — [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738), squash `9d7a1b7a`, 23 Miami link pins (session 145, 2026-09-05), shipped together with the 13 Studio Gang pins below on the same branch.** All four checks green; **verified against the LIVE Supabase RPC, not the workflow's green tick** — it serves `linkPins` **1,237** with **0 of the branch's pins missing** and **0 pins wrongly inside `tours`**, and the gh-pages mirror converged to the same 1,237 / 345 / 1,552 / 121. Session-99 dropped-key check clean on that payload (`priceTier` 1,553 with 66 priced, `isPrivate` 366, `country` 1,552, `videoRole` 1,553, places 121). ⚠️ **The RPC reads 1,553 tours / 366 makers against the catalogue's 1,552 / 345** — the documented `Zxxx` test tour and upsert-only maker accumulation; **assert on link-pin counts, never on maker totals.** 🎉 **The expected `Tours.json` conflict never materialised** — the parallel `@itshistoryonair` session had still not merged its catalogue change, so `main` was untouched at `89bb15c8` and the merge was clean; **that conflict now falls to them.** `linkPins` **1,214 → 1,237**, `makers` **331 → 345**; `tours` and `places` byte-identical. Content only — no Swift, no SQL, no build. ⚠️ **One `scripts/` file changed too** (`validate-tours-mirror.py`, developer tooling, auto-merge class — it does not ship in the app). Heroes live on gh-pages (`88add69`), **all 23 hash-verified against the uploaded bytes after the deploy**; `check-image-duplicates.py --pins` **OK** over 1,232 images, shared-URL half **0 errors / 208 documented reuses**.
  - ✅ **BOTH STACK-CAP FINDINGS ARE CLOSED — the owner made them places (2026-09-05, *"Make places for all suggested"*); see the follow-up PR line at the top of this board.** They were: **FOUR pins on the Faena's single coordinate** — the penthouse twice by two creators, Tierra Santa and Los Fuegos — **past `TourSetMap.maxStacked = 3`**, with ⚠️ **all four different creators**, so the cap bit the Home map and shared lists rather than a creator page; and **THREE on The Surf Club's**, exactly at the cap with no headroom. 🔴 **OSM maps none of the inner venues separately** (three bounded queries returned nothing inside those footprints), so siting them apart would have been the manufacturing session 132 rejected for Arthur Ashe — **a place was the fix, and is now built.**
  - ✅ **THE THIRD, FRIENDLIER CANDIDATE IS A PLACE TOO:** `The Garden at Patch of Heaven` landed **0.0 m** from the existing `@miamibucketlist` pin — two creators, one site (the Cube House / Vizcaya shape). ⚠️ **It was retitled for that reason** (the Railway Museum precedent) and the retitle stands: two identically-titled pins on one point read as a duplicate even inside a place.
  - ⚠️ **THREE WEAK HEROES, keep or pull.** **Glaser Organic Farms is the weakest** — a generic garden path with nothing naming the farm; **The History of The Surf Club** is an anonymous plaster corridor; **The Faena Penthouse Suite** stays creator-forward even after its re-crop.
  - 🔴 **THE HEADING NAMED THE WRONG CITY TWICE.** **Link #1 is an already-live TORONTO pin**, and one of the 23 is explicitly **Orlando** (its own caption says so) — it ships `city: "Orlando"`. **Read the payload, not the heading.**
  - ⚠️ **`Jade Signature` is Herzog & de Meuron and carries NO architect tag** — they are in the vocabulary and did design it, but its caption names no architect (the Jules Dalou rule). **Do not "finish the job."**
  - 🔴 **A REAL MIRROR BLIND SPOT CLOSED, AND IT WAS CHECKED AGAINST THE SWIFT FIRST.** 20 faults injected against this batch's own rows caught 19; the miss was `malformed sourceURL`, and **`validate-tours.swift` really does error on it** (lines 556-562, plus an empty `sourceAuthor` and either field on a non-link tour). All three added and pinned — selftest **24/24 → 27/27**, re-run **20/20**. ⚠️ **`load_vocab()` returns `(facets dict, flat tag set)`** while `check()` takes `(cat, facets, vocab, dom)` — one wrong guess costs a run.
  - ⚠️ **`check-place-candidates.py` 16 EXACT → 19, NEAR unchanged at 53**, the diff proving the three added groups are exactly Patch of Heaven ×2, Faena ×4 and Surf Club ×3 — nothing manufactured, nothing dodged. ✅ **All three have since been resolved into places, taking it back to 15 EXACT.**

✅ **MERGED AND LIVE — 13 Studio Gang link pins (session 144, 2026-09-05), shipped in [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738) (squash `9d7a1b7a`) alongside the Miami batch above.** Confirmed on the live RPC: all four Arkansas Museum of Fine Arts pins serve on the identical coordinate `34.7383258, -92.2663529`, so **the four-deep group is live and the cap finding stands.** `linkPins` **1,201 → 1,214**, `makers` **328 → 331**; `tours` and `places` byte-identical. Content only — no Swift, no SQL, no build. Heroes are live on gh-pages (`d22dca3`), all 13 hash-verified against the uploaded bytes.
  - ✅ **THE AMFA CAP IS CLOSED — the owner made it a place (2026-09-05).** It was **FOUR coincident markers**, past `TourSetMap.maxStacked = 3`, so the fourth was permanently unreachable on every maker, place and list map — and **three of the four are `@studiogang`**, so that creator's own page sat exactly at the cap. 🔴 **The Gilder Center is STILL OPEN and is effectively three deep** (two already-live pins plus this one) while `check-place-candidates.py` reports it as **two**, because the existing pair differs in the 6th decimal (the CalAcademy artifact defeating the EXACT tier). **A place is the fix; it was not created.**
  - ⚠️ **FOUR HEROES ARE NOT PHOTOGRAPHS OF A FINISHED BUILDING — keep or pull is the owner's call.** An architecture practice's own feed skews to drawings: a **crayon-textured plan diagram with no building in frame** (the weakest), an axonometric, the High Line path with the building unidentifiable, and a construction aerial. Precedents run both ways — Mercedes-Benz Stadium was pulled; the Koons/LACMA and Hugo de Grootplein heroes were kept.
  - ✅ **11 Hoyt keeps `city: "Brooklyn"` — OWNER DECISION 2026-09-05 (*"11 hoyt is Brooklyn"*). CLOSED; do not normalise it to `New York`.** It was raised because the dominant link-pin convention is `New York` (94 Brooklyn-coordinate pins against 10), but the caption and both neighbouring pins say Brooklyn. ⚠️ **A future consistency sweep over `city` will flag it again; it is settled.**
  - ✅ **The expected `Tours.json` conflict did NOT occur — this branch merged clean.** The parallel session pushed 41 `@itshistoryonair` heroes to gh-pages (`94264b6c`) but **still has not merged its catalogue change**, so `main` was untouched at `89bb15c8`. 🔴 **The conflict is now THEIRS**: both sides append to `linkPins` and `makers`, and `main` has moved 36 pins and 17 maker rows underneath them. **They must take `main`'s file and re-run the idempotent assembler — never hand-resolve a JSON conflict.** ✅ **THEY DID — see [#737](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/737), merged after this.** Main's `Tours.json` was taken wholesale and the assembler re-run on it; its own assertions (already-pinned sourceURLs, tour ids, stop ids) all held, and hero filenames were checked separately since the assembler does not cover them. **Overlap between the two batches was 0 on every axis.** Merged reality: **1,278 pins · 346 makers.**

✅ **MERGED AND LIVE — [#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734), squash `008c9154`, 33 Toronto and Mississauga link pins + six places + two architects (session 143).** **Verified against the LIVE Supabase RPC, not the workflow's green tick:** `linkPins` **1,201** and `places` **121**, both matching the catalogue exactly; **Toronto pins 25 → 52, Mississauga 0 → 6**; all six places served; `Raymond Moriyama` on 3 entries and `E. J. Lennox` on 6, **all 9 keeping the shelf tag**. ⚠️ #733's eight names are live too (`Shin Takamatsu` ×3, `Kim Swoo-geun`, `Timo Suomalainen`), which is the proof **the merged vocabulary shipped whole rather than one side clobbering the other**. Session-99 dropped-key check clean: `priceTier` on all 1,553, places 121, **0 pins wrongly inside `tours`**. ⚠️ **The live RPC reads 1,553 tours / 348 makers against the catalogue's 1,552 / 328** — the documented `Zxxx` test tour and upsert-only maker accumulation; **assert on link-pin counts, never on maker totals**. 🔴 **#733 merged while this PR sat open with green CI**, touching the same two vocabulary files and the same three JSON arrays. Both sides proved **purely additive — 0 rows changed by both, 0 id collisions, and no overlap between this branch's 2 architect names and #733's 8** — so `Tours.json` was **rebuilt deterministically from `main`'s file plus this branch's id-keyed deltas, never hand-resolved**, and both vocabularies auto-merged to **429, identical, 0 duplicates**. ⚠️ #733 also claimed `archive/HANDOFF-260904-2.md` (add/add), so this session's handoff renumbered to **`-3`**; and keeping both sides of the CLAUDE.md conflict **duplicated the Key facts count line**, collapsed back to one and re-derived. ⚠️ **Still owed: the simulator look at the architect shelves** — this is a code change and a Linux web session cannot run one; CI's simulator build + unit tests were the stand-in and were green. ⚠️ **The check-run API lagged badly here** — it reported `in_progress` for ~20 minutes after the unit-test job had already passed at 02:32:42. **Read the job's steps, not the check-run status.** Cut clean off `origin/main` `5763c137`, then **merged with `main` FOUR times mid-flight** (#731, #728, #732, and finally **#733** — 17 more pins, the Serlachius place and eight more architects — which landed while this branch sat open with green CI). 40 owner-supplied Instagram links → **37 distinct posts** (three pasted twice) → **33 shipped, 1 blocked, 3 dropped as duplicates**. This branch contributes **+33 pins · +23 makers · +6 places · +2 architects**; on the final merged base that reads `linkPins` **1,168 → 1,201** · `makers` **305 → 328** · `places` **115 → 121** · architects **427 → 429** · `tours` **byte-identical** apart from 6 architect tag edits. 🔴 **The #733 merge was reconstructed, never hand-resolved** — both sides proved **purely additive with 0 rows changed by both and 0 id collisions**, so `Tours.json` was rebuilt from **`main`'s file plus this branch's id-keyed deltas** and every main row asserted present, unchanged and still a prefix; both vocabularies **auto-merged to 429, identical, 0 duplicates, no overlap between the 2 and the 8**. ⚠️ **#733 also claimed `archive/HANDOFF-260904-2.md`** — an add/add collision, so this session's handoff renumbered to **`-3`**. Re-verified on the merged base: mirror **24/24 with a clean control**, then **0 errors, 0 warnings across 1,552 tours + 1,201 pins + 121 places** at 479 tags; seed clean at **328 / 2,753 / 3,125 / 121** with **0 `images//`**; 🎉 **`check-place-candidates.py` byte-identical to `main`'s at 12 EXACT — this branch adds no coincident group and removes none** (NEAR 52 → 53). ⚠️ **The follow-up made this a CODE change** (`Models/Tag.swift` + `scripts/validate-tours.swift`), so it wants a simulator look — **but no SQL**: the seed carries all of it, so it reaches Supabase on merge with **nothing for the owner to run**. ✅ **All four CI checks GREEN on `2b171cae`** — Validate Tours.json, Build (iOS Simulator), Run unit tests, Vercel.
  - ✅ **THE SIX PLACES ARE BUILT AND THE TWO ARCHITECTS ADDED — owner instruction *"Make the places. Add the architects"*. Places 114 → 120; vocabulary 419 → 421.** Four resolve this batch's own EXACT groups (Biidaasige Park + its basketball tree, the Unfinished Arch, the Toronto Reference Library, Waterworks Food Hall); two resolve the pairs the checker structurally cannot see (Museum Station, Ripley's Aquarium). 🔴 **The pin moves, never the tour** — Ripley's Atlas tour is `geofenced`, so it anchors and its pin moved **13.84 m**; Museum Station's moved **0.04 m**; both `manual`, asserted first, and **the assembler refuses to move a member that is not**. Nothing else moved. ⚠️ **Five heroes are borrowed and that is structural** (every member a link pin with an empty gallery, no Atlas tour at those sites); **Ripley's takes a real third photograph** from the Atlas tour's own gallery. Borrowed-hero count re-derived **45 of 120**. 🔴 **The architect sweep found both names already in existing Atlas tours carrying no such tag** — Bata Shoe Museum, Old City Hall, Casa Loma, Queen's Park's rebuilt west wing, and both walks whose stops those are; **8 entries gained 14 tags**, `Designed by a Master` kept on every one. ⚠️ **`The Annex` is deliberately NOT tagged** (*"often credited to"* a neighbourhood **style**, not authorship — the Sullivan rule) and **`Jones + Kirkland` were NOT added** (the Mississauga Civic Centre caption names no architect, and an unused name cannot ship). ⚠️ **This makes the PR a CODE change**, so it wants a simulator look. Verification: **76 faults injected against the six new places and the architect tags — 74 caught, control clean**; the two misses are rules the mirror never enforced and are **asserted directly (0 and 0)**. Mirror **0 errors, 0 warnings** across 1,552 tours + 1,184 pins + 120 places at 471 tags. 🎉 **`check-place-candidates.py` EXACT 15 → 11, NEAR unchanged at 51** — falls by exactly the four resolved, gains nothing, and **11 is main's own baseline, so this batch now contributes ZERO EXACT groups**. Seed clean at **328 / 2,736 / 3,108 / 120**; all six place heroes live **200**.
  - 🔴 **ONE POST IS BLOCKED AND CANNOT SHIP — proven, not assumed.** `DJUA6mbNMBi` returns **`contextJSON: null` at ~215 KB** on three spaced attempts, while a live control fetched in the same pass with the same UA returns **256,575 bytes every time**. No handle, no caption, and **no `display_url`** — so there is no subject and no hero, and a pin without one cannot exist. 🔁 **Blocked to a logged-out reader, not deleted.** ⚠️ **Do NOT re-wire it on "the link opens on my phone"** — the owner is signed in; a logged-out Atlas user gets a blank card.
  - ⚠️ **SIX POSTS ARE MISSISSAUGA, NOT TORONTO — the heading was read against the payload rather than trusted** (the session-135 rule). They ship `city: "Mississauga"`, which is **new to the catalogue**. Everything else is inside Toronto proper.
  - ✅ **TWO PLACE CANDIDATES THE CHECKER STRUCTURALLY CANNOT SEE — flagged by hand, and BOTH ARE NOW BUILT** (see the places bullet above). **Museum Station** landed **0.05 m** from the existing `@explorewithkevs` pin of the same station — a 6th-decimal difference, which defeats the EXACT tier, while the titles defeat the NEAR tier (the documented Grand Central / Textile Conservation Lab blind spot). **Ripley's Aquarium** landed **13.8 m** from the live Atlas tour. **Neither coordinate was nudged to manufacture a group**, so resolving them removes nothing from the checker's report — which is why EXACT falls by exactly the four in-batch groups and not six.
  - ✅ **ALL 33 HEROES OPENED AND READ AGAINST THEIR CAPTIONS — ZERO WRONG SUBJECTS**, and **three vague captions were closed by the pixels alone** (Bay Adelaide Centre, Curiosa, Riverdale Park East). ⚠️ **The Riverdale identification is an inference from the picture and is stated as one** — independently corroborated by the reverse-geocode landing on a sports pitch on Broadview Avenue, which is the running track in frame.
  - ⚠️ **FIVE SPEC ISSUES WERE CAUGHT BEFORE SHIPPING AND FIXED RATHER THAN SHIPPED** — one unknown tag (`Postmodern`, absent from the styleEra facet) and four entries carrying a Place type and an Experience tag but **no Theme**. Fixed by following the dominant park convention rather than inventing one.
  - 🔴 **TWO REAL BLIND SPOTS FOUND IN `validate-tours-mirror.py` AND CLOSED — and a third that was a rule I invented.** `duplicate maker id` and `stop order != 0` are genuine (the Swift errors on both, lines 414 and 572-576) and are **now mirrored and pinned in its selftest, 22/22 → 24/24 with a clean control**. ⚠️ **`non-https hero` is NOT a rule** — `isValidURL` requires only a scheme and a host, so `http://` is valid; **session 142 made this exact mistake and recorded it, and it was made again here. Read the Swift rule before calling a miss a blind spot.** ⚠️ The fault harness also under-counted its own misses on the first run by ignoring **warnings** — the documented session-141 harness bug, live again.
✅ **[#733](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/733) — MERGED (squash `7137d842`) on owner instruction, and VERIFIED AGAINST THE LIVE SYSTEMS rather than the merge's success line.** At that moment the Supabase RPC, which the app reads FIRST, served **1,168 linkPins / 115 places** with **0 pins wrongly inside `tours`**, the gh-pages mirror matched, and the session-99 dropped-key check was clean on that payload (`priceTier` on all 1,553 with 66 priced, `isPrivate` on every maker, `country` on 1,552, `videoRole` on 1,553). ⚠️ **Those counts are a dated measurement of this merge, not the catalogue's current size** — #734 merged 33 more pins and 6 more places within the hour. ⚠️ **The RPC returned HTTP 500 `57014 canceling statement due to statement timeout` while the seed job held the table, and 200 once it finished** — the documented transient class; **do not read one 500 as a broken deploy.** ⚠️ **The gh-pages mirror lagged ~5 minutes behind the publish job's own verify step**, which checks the committed blob rather than the CDN. Session 143: 17 `@archimarathon` pins + the Serlachius place + **eight** architects (**419 → 427**). The story is now in `CLAUDE.md` § Current State.
  - 🔴 **STILL OWED — the simulator look.** This merged as a **CODE PR** (`Models/Tag.swift` + `scripts/validate-tours.swift`) on the owner's explicit instruction with all four checks green, but **nothing was compiled locally and nobody has yet seen the architect shelves on a screen.**
  - ⚠️ **THREE OWNER DECISIONS ARE SETTLED — do not undo them.** **The four weak heroes are CLOSED** (*"Don't worry about weak heroes"*); anyone re-running the open-every-hero audit will flag all four again and they are settled. **The two Jules Dalou omissions were REVERSED on instruction** — `Kenzō Tange` on Yoyogi and `Timo`/`Tuomo Suomalainen` on Temppeliaukio, each alongside `Designed by a Master`; both captions genuinely name no architect, so **do not "restore" the omission.** **The Serlachius place's hero is BORROWED from a member and that is structural** — do not source a replacement.


✅ **[#730](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/730) — MERGED (squash `5763c137`), verified live on the Supabase RPC at 1,151 linkPins / 114 places.** 104 link pins from `@archimarathon`, session 142's SECOND batch. 106 links → **105 distinct posts → 104 shipped** (one link pasted twice; one post names no place and is **parked, not guessed**). `linkPins` **1,047 → 1,151**; `tours`, `makers` and `places` byte-identical, **0 new maker rows** — the uuid5 scheme reproduced the live `@archimarathon` id exactly, and its avatar regenerated byte-identically and was **excluded rather than overwritten**. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with **nothing for the owner to run**. Heroes on gh-pages `1d0ca6d6` (tree diff **exactly 104 additions, 0 deletions, nothing outside `images/`**; the deploy read **`in_progress`, never `cancelled`** against the Actions API, then **all 104 live URLs hash-verified against the uploaded bytes — 104 ok, 0 mismatch, 0 non-200**, after which `check-image-duplicates.py --pins` reads **`OK` over 1,146 images**, shared-URL half **0 errors / 208 documented reuses**). **Philippines is the catalogue's 45th country**; 22 new cities. **Both flagged owner decisions have since been ACTED ON — see the follow-up block above.**
  - ✅ **THE BARCELONA PAVILION IS NOW A FIVE-MEMBER PLACE (owner instruction).** The other eleven EXACT groups remain, all inside the cap. Original finding: 🔴 **TWELVE EXACT COINCIDENT GROUPS — `check-place-candidates.py` goes 0 → 12 and exits 1, ending the clean-exit state.** Every one is genuine (a multi-part series about one building, or convergence on OSM's own node) and **nothing was nudged together to manufacture one**. ⚠️ **The Barcelona Pavilion is the one that actually bites**: its existing place holds 2 members and this batch adds 3 more pins on the same point, so the site now carries **one capsule plus three loose pins against `TourSetMap.maxStacked = 3`** — past the cap, which puts a marker permanently out of reach on a shared list. **Joining them to the existing place is one line per pin.** The other eleven (ParkLife ×3, Yumebutai ×3, Equilateral House ×3, M+ ×3, Kyūkyodō ×2, Unitarian Meeting House ×2, ArtCenter ×2, plus Nishisando / HKDI / Tai Kwun / Serlachius forming with live content) are all inside the cap.
  - ✅ **THE ARCHITECT GAP IS CLOSED (owner instruction) — 36 names added to both vocabularies, 383 → 419.** Original finding: ⚠️ **named architects absent from the vocabulary, shipping the generic tag** — Paul Rudolph, Gordon Bunshaft / SOM, Pierre Jeanneret ×2, Arne Jacobsen, Junya Ishigami, Reima Pietilä, Roche & Dinkeloo, Schindler, Greene & Greene, Studio Gang, Atelier Oslo, Leandro Locsin, Berlage and Austin Maynard ×3 among them. **A `Models/Tag.swift` code change, kept out of a content batch.**

✅ **[#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729) — MERGED (squash `32531c71`), verified live.** 61 link pins from `@archimarathon` plus TWO places and 48 architects (session 141). `linkPins` **986 → 1,047**; `tours`, `makers` and `places` byte-identical, **0 new maker rows**. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with no owner SQL. **Two owner decisions are flagged and NOT acted on:**
  - ✅ **The two EXACT place candidates were BUILT on owner instruction (*"Make the places. Open PR"*)** — **Depot Boijmans Van Beuningen** and **Sayama Lakeside Cemetery**, places **112 → 114**, nothing moved (both pairs already coincident), and `check-place-candidates.py` returns to **0 EXACT, exits 0, NEAR unchanged at 39**. ⚠️ Both heroes are **borrowed from a member and that is structural** — no Atlas tour at either site, every member's gallery empty. ⚠️ **Sayama takes the chapel exterior over the community hall's finer interior**, on the establishing-shot criterion; one line swaps it.
  - **4 weak heroes, flagged not fixed.** **Rozet** is the sharpest — its frame is the library's interior stair rather than the Arnhem streetscape its caption is about. A link pin re-hosts only the thumbnail, so no other frame exists; the choice is keep or pull. ⚠️ **The other three are milder** and are named in `archive/HANDOFF-260903-2.md`.
  - ✅ **The architect gap is CLOSED on owner instruction (*"Definitely add those architects"*)** — **48 names added to BOTH vocabularies (335 → 383, total tags 385 → 433), 52 entries gained 62 tags**, `Designed by a Master` kept on every one. ⚠️ **This makes the PR a CODE change** (`Models/Tag.swift` + `scripts/validate-tours.swift`), so it wants a simulator look; CI is the compile check. Catalogue-wide after: **593 named-architect entries, 0 missing the shelf tag, 0 of 383 names unused.** ⚠️ The sweep found `Alvar Aalto` mentioned at Triennale di Milano and Stockholm Public Library and `James Stirling` at Palazzo Citterio — **all three are mentions, not authorship, and are deliberately untagged.**

🟢 **[#726](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/726) — branch `claude/tour-links-tp9fwp`, 29 link pins from `@archiwhisperer` and Avant Arte, plus Alwyn Court as a place and a third Guggenheim member (session 140).** `linkPins` **957 → 986** on the merged base; `tours`, `makers` and `places` byte-identical. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with **nothing for the owner to run**. Heroes on gh-pages `44d7cc00`, **all 29 live URLs hash-verified against the uploaded bytes (29 ok, 0 mismatch, 0 non-200)**; `check-image-duplicates.py --pins` run **after** the deploy: **`OK`** over 981 images, shared-URL half **0 errors / 208 documented reuses**. Mirror **22/22 with a clean control**, then **0 errors, 0 warnings** across 1,552 tours + 986 pins + 111 places; **`check-place-candidates.py` holds at 0 EXACT and exits 0 on both sides**, NEAR 36 → 43. **Serbia is the 42nd country.** ⚠️ **`main` moved twice mid-session** (#722, #725) and `Tours.json` conflicted — resolved by taking `main`'s file and **re-running the idempotent assembler**, every check re-run. ✅ **FOLLOW-UP, same session — three owner decisions applied** (*"Alwyn court - make place. Guggenheim - add to place. Gilder center keep separate"*): **places 111 → 112.** **Alwyn Court is now a place** with all three pins as members, anchored on **OSM way 265147967**, which reverse-geocodes by name — so the stack cap no longer applies. ⚠️ **One member was already exactly on the anchor and did not move** (the build's first revision demanded that every member change and correctly refused to run); the other two moved **0.1 m** and **11.6 m**, all three asserted `manual` first. ⚠️ **Swept 400 m rather than trusting the checker's pairs** — The Osborne 82 m and Carnegie Hall 97 m correctly excluded. 🔴 **Its hero is borrowed from a member and that is structural** (three link pins with empty galleries and no Atlas tour at the site) — borrowed-hero count re-derived **38 of 112**; ⚠️ all three candidates were rendered and looked at, and **`@hereinnyc`'s is the better picture, rejected on the establishing-shot criterion** — one line swaps it. **The Guggenheim pin joined its existing place as a third member** (a 29 m move of a `manual` pin; the place's hero stays a third photograph). **The Gilder Center stays separate.** `tours` and `makers` byte-identical; **exactly 3 pins changed, in exactly their four coordinate fields**; diff **30 insertions / 13 deletions**. Mirror **22/22 with a clean control**, then **0 errors, 0 warnings** across 1,552 tours + 986 pins + 112 places; ⚠️ **18 place-layer faults injected against the two changed places — 18/18 caught, control clean**, exit code read directly. 🎉 **`check-place-candidates.py` holds at 0 EXACT and exits 0 on both sides, NEAR 43 → 38** — the diff proves it fell by **exactly the five pairs resolved** and gained nothing. Seed clean at **305 / 2,538 / 2,910 / 112**, **0 `images//`**, both place heroes live **200**.

**Nothing on this batch is waiting on the owner — both open questions are now closed:**
  - 🔴 **A POST IS PARKED AND CANNOT SHIP WITHOUT A DECISION — the Andreas Gursky reel** (`https://www.instagram.com/reel/CxgEBMxqcQX/`). Its caption names **no place**, its hero is **a portrait of the artist against a concrete wall with his name burned in** (not a photograph of anywhere), and **the two coordinates supplied for it are 7,006 m apart**: the Plus Code `8QC7XPRV+JC` decodes to Yanggak in central Pyongyang, the raw pair `39.0495750, 125.7752194` lands near the Rungrado May Day Stadium. Gursky's Pyongyang series photographs the Arirang Mass Games at that stadium, which favours the **raw** coordinate — **but that is inference and the post itself supports neither**, so it was handed back rather than guessed at (the session-112 precedent). ⚠️ **North Korea would be the catalogue's 43rd country.** **Owner: give one point, or drop it.**
  - **✅ CLOSED 2026-09-03 — the owner left it. *"Ok leave the gursky"*.** It was never wired, so this costs **no catalogue edit and owes no SQL** — a post that never reached `Tours.json` never reached Postgres (verified: `CxgEBMxqcQX` is absent from both the live RPC and the gh-pages mirror). **Do not re-raise it, and do not site it later from the raw coordinate** — the May Day Stadium reading is inference, which is exactly why it was parked.
  - ✅ **RESOLVED 2026-09-03 — Alwyn Court is a place, the Guggenheim pin joined its existing place as a third member, and the Gilder Center stays separate** (owner: *"Alwyn court - make place. Guggenheim - add to place. Gilder center keep separate"*). Places 111 → 112. **Do not re-raise any of the three.**
  - ✅ **Five weak heroes flagged — the Koons/LACMA pin was the likeliest pull and the OWNER KEEPS IT (2026-09-03: *"i'm fine with the koons"*). CLOSED; do not re-raise or quietly pull it.** Its hero is Jeff Koons holding two edition pieces, its caption is a limited-edition draw that **closed on 17 March**, and its only tie to a place is *"launched in support of @lacma"*; the supplied coordinate is exactly 5905 Wilshire, **4.3 m from the live Atlas LACMA tour**. Also weak: **Calder Gardens** (motion-blurred planting, **no building visible**), **Princeton University Art Museum** (a dim interior corridor), **the Studio Museum in Harlem** (an **archival B&W** of the 125th Street building, not the new Adjaye one), and **Wim Delvoye's X-Ray Windows** — whose Ghent coordinate reverse-geocodes to a **bare house number with no venue in OSM at any zoom**, with Caermersklooster 124 m away but nothing confirming it, so **no venue is asserted**.
  - ⚠️ **Three architect tags are practice→person mappings and are judgements**, following the `Foster + Partners`→`Norman Foster` precedent: caption says **OMA** → tagged `Rem Koolhaas`; **David Adjaye** → `Adjaye Associates`; **Studio Gang** → `Jeanne Gang`. One line each to reverse. 🔴 **The Studio Museum is deliberately NOT tagged `Adjaye Associates`** although he designed its new building, because that caption names no architect — **do not "finish the job."**
  - ⚠️ **7 of 15 Instagram pins will not play inline** — the documented licensed-music gate; poster + OPEN IN INSTAGRAM is the correct outcome. One also reports `copyright_blocked: true`.


⚠️ **`gh pr list --state open` re-derived 2026-09-02 20:25 UTC — exactly THREE open PRs: [#723](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/723) (Kowloon Hum place), [#722](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/722) (19 Hong Kong + Macau pins) and [#717](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/717) (closing the `@notbadgalriri__` decisions).** **#721, #715, #714 and #716 have all MERGED** — the entries below that still say OPEN are stale on the PR and were left alone only because each still carries an owner decision that is genuinely open. **Re-derive before trusting any line on this board.**

🟡 **[#722](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/722) — branch `claude/more-tours-a1xhw4`, 19 Hong Kong + Macau link pins (session 139), sent in two waves.** `linkPins` **905 → 924** · `makers` **297 → 303** · **`places` 108 → 111** (the three candidates, built on owner instruction) · `tours` byte-identical. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with nothing for the owner to run.
  - 🔴 **Two of the first sixteen links CANNOT be pinned, ever.** They are Instagram **story highlights** (`/s/…`) by a third creator, `@kieranbrowntravel`. `LinkSource.embedURL` matches only `p`/`reel`/`tv`, so the app can build **no player**; the page also carries no `display_url` (no hero) and no caption (no subject). ⚠️ They are **NOT dead and NOT blocked** — do not re-try on "the link opens on my phone". Their two Plus Codes are orphaned.
  - ✅ **ALL THREE PLACE CANDIDATES ARE BUILT — owner instruction *"make the 3 places"*. Places 108 → 111.** **Hong Kong Railway Museum** · **In's Point** · **Bowrington Bridge Villain Hitting**, each two pins by **different creators** on one site (the Cube House shape, not the duplicate-Cheung-Hing shape); pins moved **0.46 / 36.57 / 25.72 m**, all `manual`, `tours` and `makers` byte-identical. 🔴 **Each anchors on a different member and the EVIDENCE decided, not seniority** — the Railway Museum and villain-hitting take the older pin (they sit on OSM's own named nodes), **In's Point takes the NEW pin because OSM carries the shop twice and only that node has the house number 530** (the Jamia Mosque rule). 🔴 **`check-place-candidates.py` could see only two of the three** — the hyphen in `Villain-Hitting` breaks its title-containment rule — so **NEAR falls 38 → 36 and nothing is removed for the third**; EXACT stays 0, clean exit both sides. ⚠️ **All three heroes are borrowed and that is structural** (every member is a link pin with an empty gallery, no Atlas tour at any site); borrowed-hero count re-derived **37 of 111**.
  - 🟡 **Three weak-ish heroes, flagged not fixed** — `The Four Columns at Kadoorie Farm` is a **historical B&W photograph of the demolished building the columns came from**; `The Rare LEGO Sets at In's Point` is the shop's **sign**, carrying none of the LEGO; `I Love Cake, Wan Chai` is **creator-forward**, though the shelves read behind her. A link pin re-hosts only the thumbnail, so no other frame exists.
  - ⚠️ **One title is a stated compromise** — `Louis Vuitton Lee Gardens` is titled for the **venue, not the Bar Leone pop-up it hosts** (so it cannot go stale), but categorised `foodAndDrink` because the post is entirely a bar visit and the catalogue has no shopping category.
  - ⚠️ **11 of 19 will not play inline** — the documented licensed-music gate; poster + OPEN IN INSTAGRAM is the correct outcome.


🟡 **MERGED — [#721](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/721) (squash `51889d67`), session 139, 32 Hong Kong link pins. The PR is closed, and TWO of its three owner decisions are now closed too.** ✅ **Verified against the systems rather than the success line:** the squash genuinely changed files on `main` (1,821 insertions across 6 files, all 32 shortcodes present, the blocked post correctly absent), the **live RPC serves 937 link pins with 0 wrongly inside `tours`** and places 107, and the gh-pages **committed blob** carries 937/299/107 while the CDN was still serving 905 — the documented lag, not a failed publish. All 32 heroes confirmed still in the gh-pages head tree, which matters because a parallel session was pushing more Hong Kong heroes on top throughout. ⚠️ **`main` moved mid-flight** — [#719](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/719) landed and was merged in with every check re-run, so the merged base reads **107 places**, not the 105 this batch was cut against. linkPins **905 → 937**, makers **297 → 299**; `tours` and `places` byte-identical. gh-pages `2baba65`, all 32 live heroes hash-verified. Three things want an owner call:
  - **✅ CLOSED — the stray Plus Code, and the answer means NOTHING MOVES.** `75M2+9X Central` was pasted beside the EONIQ reel but decodes onto Aberdeen Street, SoHo, 13 km from the Tsuen Wan address that reel's own caption gives; EONIQ ships on the caption. Owner named its real post: **`DTK5kAFk6Dx` — Chez Trente**, which had *already* been pasted with its own code (`75J2+WX Central`), so **the venue was given two codes at different times under adjacent links**. Measured: `75J2+WX` reverse-geocodes to **house 4-6, Chung Wo Lane** (Chez Trente's published address is **6 Chung Wo Lane**, forward geocode 10 m away) while `75M2+9X` is **117 m off on 20 Aberdeen Street**. **The pin already sits on the door and was deliberately NOT moved.** 🔴 **Do NOT "fix" Chez Trente onto Aberdeen Street** — a hand-dropped code is a tap on a map, and the venue's published address outranks it.
  - **✅ CLOSED — `Heartwarming` STAYS (owner, 2026-09-02: *"keep heartwarming"*). Do not re-raise or replace it.** Its hero is the creator walking a street with no view of the shop or its sesame desserts — the batch's weakest — and a link pin re-hosts only the thumbnail, so keep-or-pull was the whole choice. Lazy Suzy, Dieci and La Petite Maison are creator-forward and stay too. ⚠️ **The open-every-hero audit will flag this again; it is settled** (the Ministry of Enterprise precedent).
  - **⚠️ STILL OPEN, but it is a DISCLOSURE rather than a question.** `Jean-Pierre` — OSM maps no 9 Bridges Street, so the pin sits between Bridges Street Market (no. 2) and Yardbird (no. 33), which bracket it. **The batch's weakest coordinate, stated rather than hidden.** Nothing to decide unless the owner knows the exact door, in which case it moves.
  - **⚠️ One post is blocked** (`C3r_kz1v9Ct`, `contextJSON: null` proven against three live controls) — blocked now, not gone; re-testable in two minutes later.

✅ **DONE — `backend/pull_pins_260902.sql` HAS BEEN RUN (owner, 2026-09-02). Nothing is owed here; do not tell the owner to run it again.** **Verified against the LIVE RPC rather than the SQL Editor's success line:** `linkPins` **907 → 905** and `@shivanidukhandee` **106 → 104**, both now matching the catalogue exactly. `Xiang Bo Bo` is gone. ⚠️ **`Cheung Hing Coffee Shop` is STILL SERVED and that is CORRECT** — the file deleted the *duplicate* (`c4071953…`, the Pineapple Bun Hunt post) and kept the surviving twin `d3bb855c…`, which is confirmed present; exactly one remains where there were two. ⚠️ **`Cheung Hing Tea Hong` is a DIFFERENT venue 2 km away and was untouched.** Session-99 dropped-key check clean on the same payload: `priceTier` on all 1,553 with 66 priced, `isPrivate` on all 311 makers, `country` 1,552, `videoRole` 1,553, **0 link pins wrongly inside `tours`**, both new places still served, places 107. ✅ **RE-VERIFIED 2026-09-02 after the owner ran it a second time** (idempotent, so the repeat cost nothing): the live RPC and the catalogue now agree **exactly at 937 link pins**, with **0 catalogue pins missing from the RPC and 0 pins live that the catalogue does not carry** — drift is zero in both directions. Both target ids are absent, the maker row is kept, and `@shivanidukhandee` reads **104 live against 104 in the catalogue**.
  - ✅ **Everything else from those ten notes is LIVE and verified field-by-field on the RPC** — five renames and all seven coordinate moves, including three that were badly wrong: **Aquatic Market sat in Luohu District, SHENZHEN** (25 km away, across an international border, while its own `country` field read Hong Kong), **Min Fong Hong** in Tai Po 13 km from the Tsuen Wan its caption names, and **Lau Hing Kee** in Tin Hau against the creator's own `#mongkok` hashtag.
  - ✅ **CLOSED — the address request is answered and the batch is finished.** Owner: ***"TAKE OUT THESE TOURS. CANT FIND A RELIABLE ADDRESS FOR THESE SO WE'RE GOING TO OMIT"*** — all eight dropped. **Nothing was deleted and no SQL is owed**: none of the eight was ever wired, so none ever reached Postgres. ⚠️ **Haidilao was NOT a ninth deferral — it was already live**, and has since been moved to Carnarvon Road on owner instruction. ⚠️ **`Lau Kee Aberdeen Boat Noodle` in the catalogue is an ATLAS NARRATED TOUR, not the dropped pin — do not remove it on a name match.** Final: **105 shipped · 11 dropped · 0 deferred · 2 blocked** of 116 pinnable — the last deferral (a second Kowloon Hum reel) was shipped on owner instruction *"if they are different reels, then add it and make it a place"*, and **Kowloon Hum is now a place**. ⚠️ **Wiring it also exposed that the LIVE pin was 281 m off the address its own caption gives** — see § 1. ⚠️ **Do not count this batch from `analysis.json`** — it carries two posts by other creators and a first pass here reported 106/118 off it, wrong by two.
  - 🟡 **STILL OPEN — 1 EXACT place candidate: The Hideout, Mui Wo** (two posts about one venue on one owner-supplied coordinate). The Cheung Hing pair that sat beside it was resolved by the owner's own "duplicate" call. ⚠️ **The perceptual check had scored that pair 55.8 — comfortably "two different pictures" — so byte and perceptual checks were both right and still could not see it. A duplicate of SUBJECT is not a duplicate of PIXELS.**

🟡 **OPEN — [#715](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/715) nineteen Hong Kong link pins from Instagram `@notbadgalriri__` (session 138)**, branch `claude/tour-links-exviiy`. Twenty links, one reel pasted twice, so **19 distinct posts ship**. **linkPins 846 → 865 · makers 263 → 264 · `tours` and `places` byte-identical.** Content only — no Swift, no SQL, no build; the seed carries `linkPins`, so it reaches Supabase on merge with **no owner SQL**. Heroes on gh-pages `e3503251`, **all 19 live URLs hash-verified against the uploaded bytes (19 ok, 0 mismatch)**; `check-image-duplicates.py --pins` **`OK`** over 860 images, shared-URL half **0 errors / 208 documented reuses**. Validator mirror **self-tested 40/40**, then **0 errors, 2 pre-existing warnings**; `check-place-candidates.py` output **byte-identical to `main`'s** (2 EXACT / 38 NEAR — nothing manufactured).
  - ✅ **CLOSED — a supplied Plus Code contradicted its own post, and the owner confirmed the caption.** `862H+Q4 Cha Kwo Ling` was pasted beside the second copy of `DZuR4QoP_8R`; it decodes onto the **Central Kowloon Bypass, a motorway under construction**, while that reel's caption gives an explicit address **15 km away** in Tsuen Wan. Confirmed three ways (OSM names 荃德花園 Tsuen Tak Gardens at **house number 208** exactly; the creator's own burned-in subtitle reads *"Nocturnal Stationery in Tsuen Wan is a humble shop"*; the code lands on a road, not a venue), so **the caption won**. ✅ **CONFIRMED BY THE OWNER 2026-09-02** (*"go with the correct location as you've placed it"*): the pin stays in Tsuen Wan, **the stray code is ignored, and there is no missing twentieth reel**. Closed — do not re-open it or move the pin onto the code's point.
  - ✅ **CLOSED — the Rednaxela Terrace hero stays.** Owner decided 2026-09-02 on sight (*"keep"*), after the live hero was **rendered and sent** rather than described. It is a wet market while the subject is beyond doubt (the code reverse-geocodes onto the terrace by name) — **the sharpest mismatch in the batch, and it ships as-is. Do not re-raise it or source a replacement** (the Ministry of Enterprise / Casa Lleó Morera precedent). 🟡 **Victoria Skypark** (a mall walkway, not the sunset-and-skyline its caption is about) and **Camelpaint Building** (street b-roll) are still open, though keeping the worst of the three effectively answers them. A link pin re-hosts only the thumbnail, so **no other frame exists** — the choice is only ever keep-or-pull.
  - ✅ **CLOSED — the toy store stays unnamed** (owner, 2026-09-02: *"leave the toy store name unknown as-is"*). Its caption withholds it (*"COMMENT 'TOY' TO GET THE LOCATION"*) and the shopfront sign is only partly legible (`…0AMPM TOYS`, its first character behind the creator's own `[13/100]` overlay), so it ships as **`A Vintage Toy Store in Tsim Sha Tsui`** — the Banksy convention. **Do not name it later from a guess; a partly-legible sign is not a name.**
  - ✅ **CLOSED — Man Luen Choon's district was raised in error and needs no decision.** The pin sits on OSM's node named for the shop (140-142 Des Voeux Road Central, which OSM files under **Central**) while the caption says **Sheung Wan** — but **"Sheung Wan" appears only inside `longDescription`, the creator's verbatim caption, and the pin's own `city` is `Hong Kong`**, so nothing this catalogue authors names a district and there is no line to move. 🔴 **Check what a discrepancy changes in the shipped fields before putting it to the owner** — two sources disagreeing is a decision only if a field we author must pick one. The siting reasoning stands: OSM *also* names Wing Cheong Commercial Building, 19-25 Jervois Street (Sheung Wan) 230 m away, and **the OSM node named for the business is the only in-session evidence tying the name to a point**, so it won.
  - ⚠️ **Ohara Ikebana ships on a street centroid and no house number was invented** — OSM maps Kam Ping Street with no addressed nodes (the Operaparken precedent). ⚠️ **Prime Steak Restaurant is in no OSM record** and sits on its code's real address point, 218-220 Sai Yeung Choi Street South (the COSM Atlanta case). ⚠️ **13 of 19 will not play inline** — the documented licensed-music gate.
  - ⚠️ **[#714](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/714) is open in parallel** (42 Miami pins + 5 places, `claude/new-tour-links-mphq67`). **Zero overlap on sourceURLs, tour ids, maker ids and hero filenames — checked, not assumed** — but both append to `linkPins`, so **whichever merges second must redo its catalogue edit the documented way: take `main`'s file and re-apply, never hand-resolve a JSON conflict.**

✅ **MERGED AND CLOSED — the `@shivanidukhandee` Hong Kong batch, now 104 of 116 pinnable posts shipped (session 137, closed session 138)** — it was 106 when these four PRs merged; #716 then removed two on owner instruction, across four PRs: [#708](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/708) (46), [#710](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/710) (3), [#711](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/711) (15), [#712](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/712) (42 new + 15 coordinate upgrades, squash `b46e354c`). **linkPins 740 → 846 · makers 262 → 263 · tours and places byte-identical.** **Verified live on the Supabase RPC — 846 pins, 106 on the maker row, 0 wrongly inside `tours`, `priceTier` on all 1,553 with 66 priced, `isPrivate` on every maker, places 100** — and the gh-pages mirror converged ~6 minutes later. All 42 new heroes **hash-verified against the uploaded blobs, 42 ok / 0 mismatch**; `check-image-duplicates.py --pins` **`OK — no suspicious duplicates`** over 841 images, shared-URL half **0 errors / 208 documented reuses**. Content only — no Swift, no SQL, no build.
  - ✅ **CLOSED 2026-09-02 — the owner dropped all eight rather than sourcing addresses.** `drafts/hk-shivanidukhandee/ADDRESSES-NEEDED.txt` is now a **closed record**, not a pending request; it names the eight shortcodes and the two catalogue entries that share a name with them and must not be removed. **Haidilao was never a ninth deferral** — that reading was wrong, it was already shipped.
  - 🟡 **STILL OPEN — 2 posts are blocked by Instagram and 1 was dropped.** `C6vyhv4NhMu` and `DW_uE17B0dW` return `contextJSON: null` (~219 KB against ~260 KB, proven against live controls in the same pass with the same UA) — **no handle, no caption, no thumbnail, so a pin with no hero cannot exist**. 🔁 Blocked now, not gone; worth a two-minute recheck in a month. ⚠️ **Do NOT re-wire them on "the link opens on my phone"** — the owner is signed in. `DViylUIjGUg` was dropped as a **reposted Disneyland clip** (perceptual distance 2.8 against its twin); one line restores it.
  - 🟡 **STILL OPEN — 8 place candidates flagged, none created.** Including **Cheung Hing Coffee Shop ×2** (two genuinely different posts, both shipped) and **The Hideout, Mui Wo ×2** (two posts about one venue on one owner-supplied coordinate). `check-place-candidates.py` reads **2 EXACT / 38 NEAR**; neither pair was nudged apart to dodge the checker.
  - ⚠️ **Three pins ship outside Hong Kong and MACAU IS THE CATALOGUE'S 41st COUNTRY** — Chagee at the Venetian and IONG'S Magic Shop (Macau, a new city), and Elco Pani Puri (Mumbai, new city; India already existed). All three reverse-verified.
  - 🔴 **One creator caption is wrong and the owner's coordinate is right.** A post captioned *"Sai Wan Ho Rock Pools"* sits **20 km** from the supplied point, which lands in **Sai Kung country park** where Hong Kong's cliff-jumping rock pools actually are — and the hero settles it independently. It ships as **`Rock Pools at Tai Long, Sai Kung`**; the creator's wording stays verbatim in their own caption.

✅ **MERGED — [#700](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/700) sixteen Hong Kong link pins (session 137)**, squash `c868a964`, **verified live on the Supabase RPC**: all sixteen present, 0 pins wrongly inside `tours`, 66 tours still priced. Owner sent sixteen Instagram reels; all sixteen shipped. **linkPins 696 → 712, makers 246 → 247.** Content only — no Swift, no SQL, no build; the seed carries `linkPins`, so it reaches Supabase on merge with **no owner SQL**.
  - 🟡 **STILL OPEN — four weak heroes are the owner's call** — **#10 The Pokfulam Farm is a close-up of a blue COW SCULPTURE** with nothing identifying the farm or Hong Kong (the likeliest pull); PMQ is a basement, Green Hub an interior jail cell, HKDI a corridor detail. A link pin re-hosts only the thumbnail, so **no other frame exists** for any of them.
  - ✅ **ALL THREE PLACE CANDIDATES ARE BUILT — owner instruction, [#705](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/705), CI green. Places 97 → 100.** PMQ, Jamia Mosque and Sai Wan Swimming Shed; the pin moved 45 / 28 / 30 m onto its tour (nothing here is geofenced, so each anchor was decided on its own evidence). **Every hero is a real third photograph** from the Atlas tour's own gallery, so nothing was sourced and these three add **zero** borrowed heroes. See `archive/HANDOFF-260901-13.md`.
  - 🟡 **STILL OPEN — ⚠️ `Coldefy & Associés` is named in a caption and is absent from the vocabulary** — the Hong Kong Design Institute ships the generic `Designed by a Master`. Adding the name is a `Models/Tag.swift` **code** change for a future architect PR.


**The test — one field decides it.** Fetch each post's embed and read `contextJSON`:

```bash
UA="Dozent/1.0 (link-pin tool; +https://dozent.world)"
for sc in Dcrfes9p-_x DVMsHoSkfHz DbODWROJUPl Day97y6Jvya DaWJQoESt0g DaDjmywBe8U; do
  n=$(curl -sSL --max-time 25 -A "$UA" "https://www.instagram.com/reel/$sc/embed" \
      | grep -o 'contextJSON":null' | wc -l)
  echo "$sc  $([ "$n" = 0 ] && echo READABLE || echo still-null)"
  sleep 3
done
```

**`contextJSON: null` → still blocked, change nothing.** Non-null → they are pinnable: run the normal
link-pin flow and they join the catalogue in minutes. ⚠️ **Always run a live control in the same pass**
(e.g. `DcTW0yzsEok`, a pin already in the catalogue) — without one, a transient failure reads as a
restriction.

✅ **MERGED — [#698](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/698) squashed as `0312ced5` (session 135): 25 Toronto link pins.** All four CI checks green (**Validate Tours.json**, simulator build, unit tests, Vercel), and the squash was **verified to have actually changed files on `main`** — 1,705 insertions across 5 files — rather than trusting GitHub's success line (the #629 empty-squash lesson). ✅ **VERIFIED LIVE ON BOTH SOURCES, read back rather than assumed from the workflow's success line:** the **Supabase RPC** (the PRIMARY source) serves **590 link pins · 25 Toronto · 0 link pins inside `tours`**, and the **gh-pages mirror** serves **590 · 25**. ⚠️ The seed took **~15 minutes** on "Apply seed" — well past the mirror job, which finished in 12 seconds — so a content merge is not live the moment CI goes green; poll the RPC. ⚠️ **The RPC reports 1,553 tours against the catalogue's 1,552** — the long-standing `Zxxx` test tour, pre-existing; **assert on link-pin counts, not tour totals.** The original PR notes follow.

✅ **All four are BUILT — see the entry below.**


✅ **MERGED — [#702](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/702) squashed as `855938a8`, and
**verified live on the Supabase RPC** (the PRIMARY source, ~2 min after merge): **91 places · 7 in Toronto ·
all three new ones present · the Royal Ontario Museum place carrying 3 members, all resolving and all on its
exact coordinate · 0 link pins wrongly inside `tours`**, with the session-99 dropped-key check clean
(`priceTier` on all 1,553 with 66 priced, `isPrivate` on all 274 makers). The squash was confirmed to have
**actually changed files** — 347 insertions across 5 — rather than trusting GitHub's success line. ⚠️ The
gh-pages mirror lags the RPC and converges on its own; the RPC is what the app reads first. ⚠️ **The RPC
reports 1,553 tours and 274 makers against the catalogue's 1,552 and 262** — the long-standing `Zxxx` test
tour and upsert-only maker accumulation, both pre-existing; **assert on place counts, not totals.** The
original entry follows.

🟡 **(superseded, kept for the decisions)** Casa Loma, the Distillery District
and Osgoode Hall become places, and the Crystal joins the ROM (branch `claude/tours-links-upload-h6t2cs`,
session 135b).** Owner: *"ROM IS ALREADY PLACE -
ADD THE NEW TOUR INTO THE PLACE, MAKE CASA LOMA A PLACE, MAKE DISTILLERY A PLACE, OSGOODE A PLACE"* —
the four candidates #698 flagged. **Places 88 → 91.** Content only — no Swift, no SQL, no gh-pages push,
no build; the seed carries `places`, so this reaches Supabase on merge with **no owner SQL**.
  - **Each new place is an Atlas Studio YYZ single-stop tour paired with the #698 link pin of the same
    subject.** The ROM place gains the Crystal pin as a **third** member beside the Museum Mile walk and
    the ROM single.
  - **🔴 The pin moves, never the tour — and the build asserts why.** All four Atlas tours are
    `geofenced` (moving one changes where its audio fires); all four pins are `manual`, so moving one
    costs nothing. Moves: **11.4 m** Casa Loma · **40.3 m** Distillery · **56.7 m** Osgoode · **9.5 m**
    the Crystal, onto the ROM place's existing coordinate. Exactly **four coordinate fields per pin**.
  - **✅ EVERY HERO IS A THIRD PHOTOGRAPH, promoted from the member tour's own gallery** — already
    uploaded, already verified, **nothing sourced**, and `hero not in member_heroes` is a hard assertion.
    **The borrowed-hero count does not move: 21 of 88 → 21 of 91.** All nine candidates were **rendered
    and looked at**, not chosen by filename.
  - **⚠️ Two hero calls are judgements and each is a one-line swap.** **Distillery takes the winter
    street-clock view** (`_6`) — the cobbled lane with the stone mill, the most *establishing* frame —
    over the LOVE-padlock wall (`_4`, warmer, no people, but one wall) and the **seasonal** Christmas
    market (`_5`). ⚠️ Its "JOHN FLUEVOG" tenant sign is legible; that is a real shopfront in a
    re-tenanted Victorian works, the Crocker Galleria precedent, not a watermark. **Osgoode takes the
    painted-ceiling hall** (`_2`) over the two courtrooms (`_3`, `_4`) — all three candidates are
    interiors, because the tour's own hero already carries the classical exterior. **Casa Loma's Great
    Hall (`_2`) was the only candidate.**
  - **⚠️ Membership was swept, not inferred from the checker's pairs.** Within 320 m: Spadina Museum
    (150 m) is a separate museum; Nathan Phillips Square (189 m) and the City Hall pin (270 m) are
    separate subjects; Gardiner Museum (111 m) and Museum Station (150 m) likewise. **🔴 The Old Town
    walk's stop 5 IS the Distillery District, 16 m away — and it is correctly NOT a member:** a walk
    anchors on stop 0, which is 1,771 m away at St Lawrence Market, and that walk is already in the
    Union Station place. A tour may belong to one place only.
  - **⚠️ Addresses are editorial, corroborated by geocoding rather than taken from it.** Casa Loma
    reverse-geocodes **by name** to *1 Austin Terrace*; Osgoode's forward geocode names it exactly at
    *130 Queen Street West*, on the pin's own coordinate. **The Distillery ships 55 Mill Street, the
    complex's published address (38 m away), not OSM's 10 Trinity Street filing** — the La Pedrera rule.
  - **⚠️ The Osgoode tour's coordinate is a deliberate vantage and was NOT moved.** It sits 57 m south of
    OSM's building node, on the Queen Street fence — which is where the cow gates are, and the gates are
    the tour's whole hook (the Grand Central / Petersen shape).
  - **Verification.** Validator mirror (vocabulary from **both** Swift files, **385 tags**) **0 errors,
    0 warnings** across 1,552 tours + 740 pins + 91 places. ⚠️ **Eleven place-layer faults were injected
    against the FOUR TOUCHED PLACES specifically — 11/11 caught, control clean** — because a suite
    written before the layer you changed is not evidence about it; the pin-layer suite is 16/16.
    `check-place-candidates.py` **NEAR 40 → 36**, falling by exactly the four pairs resolved, with
    **EXACT unchanged at 7**, so no coincident group was manufactured (all six are other sessions' or
    the Cube House pair the owner chose to keep); ⚠️ exit code read **directly, not through a pipe**.
    `seed_from_toursjson.py` clean at **262 / 2,292 / 2,664 / 91**. `Tours.json` **byte-stable under a
    Python re-dump** before and after editing; **`tours` and `makers` byte-identical to `main`**, exactly
    4 pins changed in exactly 4 fields each. All four place heroes live **200**.
  - ⚠️ **`main` moved mid-session** **four times** (#698, #699, #700 and #701 — the last two **after CI had already gone green**), so each time the catalogue edit was **redone the documented
    way — take `main`'s file and re-run the idempotent assembler, never hand-resolve a JSON conflict** —
    and every check above was re-run afterwards. ⚠️ **Nothing compiled — CI on
    [#702](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/702) is the authoritative validator.**


🟡 **OPEN — [#691](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/691) two place cards, and seven
slashes (branch `claude/tour-links-upload-vhsf8a`, session 134).** Owner: *"arthur ashe place page yes"*,
then *"make banyan tree mayakoba a place page"*. **Places 80 → 82.** Content only — no Swift, no SQL, no
gh-pages push, no build; the seed carries `places`, so it reaches Supabase on merge with **no owner SQL**.
  - **Both are pure additions and nothing moved** — `makers`, `tours` and `linkPins` byte-identical, both
    member groups already exactly coincident. **🔴 Arthur Ashe was hitting `HomeView.maxStackedPlacecards`
    with no headroom; a place collapses its members into one capsule pin, so the cap stops applying.**
  - **🔴 Both heroes are borrowed from a member and that is structural** — every member is a link pin with
    an empty gallery and a 5 km sweep found no third photograph of either site. **Do not go sourcing
    replacements.** ⚠️ **The renovation pin is excluded as a hero because it is a rendering, not a
    photograph** — it stays a member.
  - **✅ The seven `@nikola.matus` `images//` stop URLs are fixed in the second commit** — the catalogue now
    holds zero, and `--pins` goes **557 images with 7 phantom groups → 550 with none**. That closes the
    item CLAUDE.md had recorded as fixed when only its hero half was.
  - ⚠️ **Rebased onto `main` mid-session** after [#690](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/690)
    landed underneath it; `Tours.json` auto-merged cleanly and **every check was re-run afterwards** —
    mirror **0 errors / 2 pre-existing warnings** over 1,552 tours + 565 pins + 82 places, seed clean at
    **226 / 2,117 / 2,489 / 82**. ⚠️ **Both sessions numbered themselves 133**; theirs was already on
    `main`, so this one is renumbered **134** and its handoff is `archive/HANDOFF-260901-4.md`.
  - **Still owed to the owner, none blocking:** three EXACT groups remain (**Grove at Grand Bay** ×3,
    **Bellevue (William O. Lockridge) Library** ×2, **Vancouver House** ×2), each a real place candidate;
    and the five weak heroes from #689 are unchanged.

🟢 **MERGED — [#690](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/690) eleven link pins from Joshua Charow**
(squash `34cae196`; linkPins 554 → 565, makers 224 → 226). Verified live rather than on the
workflow's success line: the **Supabase RPC serves all 11 pins and both maker rows, 0 pins wrongly
inside `tours`**, and the gh-pages mirror converged byte-identical after ~3 min of CDN lag.
**✅ Both questions it raised are CLOSED by the owner — do not re-raise either:**
  - **The same reel ships as TWO pins** (the Bedi Makky foundry and the Charging Bull) — *"IT'S FINE
    THERE ARE 2 OF THE SAME REELS AT DIFFERENT LOCAITONS"*. ⚠️ The Bull pin's photograph is a foundry
    in Greenpoint; **that is the accepted cost, not an oversight**, and an open-every-hero audit will
    flag it again.
  - **The Charging Bull is now a place** and **the Textile Conservation Lab is the cathedral place's
    fifth member** — [#693](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/693), on owner
    instruction. **Places 82 → 83.**

🟡 **OPEN — Riverside Church becomes a place, and its Atlas tour stops firing on Broadway
(branch `claude/place-riverside-church`, session 134c).** Owner: *"i have a new 'place' to report.
riverside church"*. **Places 86 → 87.** Content only — no Swift, no SQL, no gh-pages push, no build.
  - **🔴 The Atlas tour's coordinate was wrong and it is GEOFENCED, so it could never fire at its own
    subject.** It sat on **3019 Broadway, 243 m from the church** and outside its polygon, while its own
    script opens *"You're on Riverside Drive at 120th Street, outside Riverside Church"* — not a
    deliberate vantage, simply wrong (the Chelsea Hotel / Leighton House shape). Anchored now on the
    church's own OSM polygon centroid, which **reverse-verifies by name**.
  - **🔴 Radius re-derived, not inherited: 60 → 100 m**, covering the building (61 m), the Riverside
    Drive pavement (74 m) and West 120th (93 m). **0 other geofenced markers within 500 m.**
  - ✅ **The hero is a third photograph** from the tour's own gallery — nothing sourced, neither
    member's hero. All six candidates rendered and looked at.
  - **🔴 A gap in the Python validator mirror was found and fixed: it checked no enum domains at all**,
    leaving it blind to the `triggerMode: "geofence"` class that once reached 18 tours. Now parsed from
    the Swift, refusing a short parse; **11/12 → 12/12**, still 0 errors on the real catalogue.

🟢 **MERGED — [#694](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/694) the last three place cards, and
a sourced Windsor hero (squash `41a667d4`, session 134).** ✅ **Verified live, not on the merge line:** the
squash actually changed files (6 files, 369 insertions), and the **Supabase RPC — the source the app reads
first — now serves 86 places** with all three present and their members resolving, the Windsor hero repointed
to `windsor-castle_hero.webp`, and the session-99 dropped-key check clean (`priceTier` on all 1,553 with 66
priced, `isPrivate` on all makers, `country` and `videoRole` intact, **0 link pins wrongly inside `tours`**).
The gh-pages mirror converged at 86 and all four place heroes return **200**. Owner: *"do the other 3
place pages"*, then *"SOURCE A HERO FOR WINDSOR CASTLE"*. **Places 83 → 86.** Content only — no Swift, no
SQL, no build; the seed carries `places`, so it reaches Supabase on merge with **no owner SQL**.
  - 🎉 **`check-place-candidates.py` reaches ZERO exact groups and exits 0** — the clean state last held
    before #674. **The place backlog is empty, and a clean exit is the expected state again: treat any
    future EXACT group as a real finding.**
  - Built **Grove at Grand Bay** (Miami, 3 pins) · **Bellevue (William O. Lockridge) Library** (Washington,
    2) · **Vancouver House** (Vancouver, 2). All **pure additions with nothing moved**. ✅ **Every
    coordinate reverse-geocodes to its subject by name**, so no polygon test was needed anywhere.
  - ⚠️ **`main` moved mid-session** (#693 made The Charging Bull a place), so the catalogue edit was
    **redone the documented way — take `main`'s file and re-run the idempotent assembler** — and every
    check re-run: mirror **0 errors / 2 pre-existing warnings** over 1,552 tours + 565 pins + 86 places,
    **11/11** injected place faults caught, seed clean at **226 / 2,117 / 2,489 / 86**, diff still
    **47 insertions / 1 deletion** with `tours`/`linkPins`/`makers` byte-identical to `main`.
  - ⚠️ **The Ribbon is a member of Grove at Grand Bay, not a place of its own** — its caption places it
    *"within the site"* (the Arab Hall shape, not the Beauchamp Tower exclusion). One line reverses it.
  - ✅ **Windsor Castle's borrowed hero is replaced with a sourced CC0 photograph of the Round Tower**,
    closing the item that had sat in this section since #679. **No CREDITS row is owed** (CC0), and the
    source is natively 4:3 so nothing is cropped or upscaled.
  - ⚠️ **One hero trade-off stated rather than hidden:** Vancouver House takes the people-free facade over
    the frame that shows the building's famous twist, because two identifiable presenters fill that one's
    bottom third. **One line swaps it.**
  - **⏸️ DEFERRED BY THE OWNER, 2026-09-01: *"for now i'm fine with the things you flagged."*** The
    **five weak heroes** from #689 — the Grand Central Stones (an elevated subway platform rather than
    the thirteen monoliths) sharpest among them, plus Banyan `@everythingeryn`, 150 N Riverside, 87th
    Street and Xcaret — and the **Vancouver House hero trade-off** (the people-free facade was taken
    over the frame showing the building's famous twist, which carries two identifiable presenters in
    its bottom third; one line swaps it). ⚠️ **"For now" is a deferral, not a decision** — unlike the
    Ministry of Enterprise and Casa Lleó Morera heroes, which the owner settled outright, these are
    still open questions. **Do not re-raise them as fresh findings** (they have been through the
    open-every-hero audit and were put to the owner), and equally **do not treat them as closed** or
    quietly source replacements. A link pin re-hosts only its thumbnail, so for each one the real
    choice remains keep or pull.

🟢 **MERGED — THE THREE PLACE/NHM ITEMS THAT SAT HERE ARE ALL ON `main`.**
[#676](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/676) ten Tier 1 place cards (places
56 → 66) · [#679](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/679) nine Tier 2 cards plus
Gracie Mansion (66 → 76, and `check-place-candidates.py` reaches **0 EXACT**) ·
[#680](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/680) the London Natural History Museum
playing Los Angeles' narration. Their stories live in `CLAUDE.md` § Current State.
  - **✅ WINDSOR CASTLE IS FIXED (session 134, [#694](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/694)).**
    It had **no picture of the castle at all** among its members (an armour, three portraits, a drawing
    room and a postbox), so its place hero was the weakest of the borrowed ones; it now carries a
    sourced CC0 photograph of the Round Tower. **One owner decision remains and blocks nothing:**
    **The Charles Dickens Museum** ships `heroImageURL: null` deliberately (the
    field is optional and falls back to the top-ranked tour's hero) because that tour's only spare
    image is a 19th-century engraving.

🟢 **MERGED (re-derived 2026-09-01: only #691 and #692 are open) — THE TWO CHECKS THAT COULD HAVE CAUGHT THE NATURAL HISTORY MUSEUM
(branch `claude/shared-url-checks`).** Owner: *"add the two missing checks"*. Tooling only —
`scripts/check-image-duplicates.py`, **255 insertions / 0 deletions**; no catalogue, Swift, SQL or
build change. **Auto-merge class** (`scripts/` does not ship in the app).
  - **🔴 The byte checker was blind to this by construction:** it compares two DIFFERENT urls
    holding the same bytes, while the NHM case is two entries pointing at the SAME url — **one file
    hashed once is one file, so it never forms a group** — and nothing anywhere touched `audioURL`.
  - Shared **`audioURL` = ERROR**; **one-source-post link pins = INFO** (the `@malata.antwerp` case,
    checked **before** the city rule because those pins are legitimately in five cities); **holders
    in two cities = ERROR**; **any `multiStop` holder = INFO**; otherwise ERROR.
  - **🔴 Deliberately NOT scoped by `--maker`/`--pins`** — the NHM collision spanned two cities and
    two makers, so any convenient scope hides the bug it exists to find. Costs nothing: no network.
  - **9 injected fault classes, 9/9 caught.** ⚠️ **The two wiring faults were MISSED first time —
    `--selftest` exits before `main()`'s body runs**, so neutering the call site is invisible to
    every logic case; the selftest now reads `inspect.getsource(main)` and asserts the wiring.
  - **Regression proof:** over `521bbb5b` it reports **8 errors** (seven images + the shared
    `natural-history-museum.mp3`); against the current catalogue **0 errors, 207 documented reuses**.

🟢 **MERGED — NINETY-FIVE LINK PINS FROM ALICE LOXTON, DOMUS AND ROME ART STORIES
([#674](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/674), merged 12:01 UTC).**
**linkPins 283 → 378 · makers 206 → 208; tours (1,552) and places (56) unchanged.** Content only.
  - **⚠️ Owner decision available, not blocking:** whether any of the ten EXACT same-subject pairs
    the owner sent twice should become places (Harvington Hall ×2, Hatfield + the Elizabeth Oak,
    Syon Park ×2, York Minster + Roman York, **Windsor Castle ×3**, Hampton Court ×2, Hever ×2, the
    National Gallery ×2, Leighton + the Arab Hall) plus **CaixaForum Madrid**, where the Domus pin
    lands on the existing Atlas tour. **Flagged, not created.**
  - **⚠️ One weak hero flagged, not fixed:** *Windsor Castle #88* is a **postbox**. Its caption is
    "Historic delights of Windsor Castle!" and Windsor does have a famous Victorian wall postbox, but
    on the map it reads as a generic red box. One line removes the pin if the owner prefers.
  - **🔴 A failure class worth knowing before the next batch:** 13 posts answered their oEmbed
    thumbnail with **52 bytes of `{"code":5009,"error":"fail to make process filters"}`** — not a
    dead post, not transient, and per-object rather than per-host. **The fix is the same post's
    `originCover` (`tplv-tiktokx-origin`)**, fed through the tool's own `best_thumbnail`. 13/13
    recovered. **If it recurs, fold the fallback into `make-link-pin.py` itself.**

🟢 **MERGED — SEVEN PLACE CARDS FROM AN AUDIT, AND `check-place-candidates.py` REACHES ZERO
([#673](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/673)).**
**places 49 → 56; tours (1,552), link pins (283) and makers (206) byte-for-byte unchanged.** Built:
**Casa Milà — La Pedrera**, **Operaparken**, **Wave Hill**, **Grand Central Terminal**,
**Chichén Itzá**, **Rosewood Mayakoba**, **Casa Lleó Morera**. The pin moved and the tour never did.
  - 🔴 **EXACT reached zero and the script exited 0 for the first time in its history** at that
    point. **CLAUDE.md's standing note that a clean exit is NOT the expected state is corrected in
    place** — treat any future EXACT group as a real finding. ⚠️ The two batches above have since
    taken it to 11; those are same-subject pairs the owner sent twice, not a regression.
  - 🔴 **The checker cannot see every candidate.** Its NEAR tier matches on title containment, so
    *The South Facade of Grand Central* and *Grand Central Terminal* never pair — run it **and** a
    hand sweep (every pair within 40 m, plus every pair within 200 m sharing a distinctive word).
  - ⚠️ **Two heroes are BORROWED from a member** (Chichén Itzá, Rosewood Mayakoba) — both are
    pin-only sites with empty galleries, so no third photograph exists. The Waterlooplein case,
    already closed by the owner: **do not go sourcing a replacement.**
  - ⚠️ **The Great Ball Court is deliberately excluded** from the Chichén Itzá place and stays its
    own pin 224 m away. **Do not "complete" it.**
  - **Still flagged, not built:** Monestir de Montserrat (31 m), Tribune Tower (142 m), Petit Palais
    (276 m), Walt Disney World Swan + Dolphin (216 m). **There is no Grand Palais candidate** — it
    has one entry in the catalogue and the pin beside it is the Petit Palais, 155 m away.

🟢 **MERGED — SEVEN `@nikola.matus` PINS, THE CHELSEA HOTEL COORDINATE, AND THE CHELSEA PLACE
([#668](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/668) `a997860a`, plus the place PR).**
**linkPins 276 → 283 · makers 205 → 206 · places 48 → 49 · tours unchanged at 1,552.** CI green on
all three jobs; verified live against the Supabase RPC **and** the gh-pages mirror, both serving
283 pins with **0 pins wrongly inside `tours`**, and `priceTier` / `isPrivate` / `country` all
intact. ⚠️ The mirror lagged Supabase by **~8 minutes** — a mirror read taken straight after a
merge will lie to you.
  - ✅ **The Atlas `The Chelsea Hotel` tour could never fire and is fixed.** It sat **290 m** from
    the hotel behind a **60 m** geofence, while its own script says *"outside the Chelsea Hotel"*.
    Stop 0 and the centroid now sit on `40.7443742, -73.9968175` (`Hotel Chelsea, 222, West 23rd
    Street`). **Radius re-derived and kept at 60 m; 0 other geofenced markers within 500 m.**
  - ✅ **The Chelsea Hotel is now a place** (owner: *"make it a place"*), **places 48 → 49**,
    `check-place-candidates.py` **4 EXACT → 3**. **Nothing moved to make it** — the pair became
    coincident when the tour was corrected. **Hero is a third photograph** from the tour's own
    gallery; place + both members are three distinct pictures. No owner SQL.
  - ⚠️ **7 of 7 pins will not play inline** — the licensed-music rights gate, `video_url` absent
    from every embed. Correct behaviour, but the first batch where a creator's *entire* output is
    withheld; **whether to keep them is a curation call.**
  - ⚠️ **Two heroes are portraits of a person rather than a place** (Marilyn Monroe, Edie
    Sedgwick). Not wrong, but they render as a face on the map; no other frame exists.

🟢 **MERGED — GLASSHOUSE THEATRE BECOMES A PLACE
([#663](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/663), `claude/tour-links-upload-3bqlib`,
restarted off `main` after #659 merged).** Owner: *"make place card for glasshouse theater."* The two
coincident pins from #659 become one place; **places 44 → 45**, `check-place-candidates.py` **4 EXACT
→ 3**. **Nothing moved** — both pins were already on the identical coordinate, so the exact-coordinate
identity rule held with no pin relocated. **🔴 The hero is BORROWED from the interior pin because no
third photograph exists**: the venue opened March 2026 and every Commons image of it is CC BY-SA 4.0,
off-policy while the app has no attribution UI. **The Hotel Casa del Mar case — do not go sourcing a
replacement.** Content only; the seed carries `places`, so **no owner SQL**.


✅ **MERGED — FOURTEEN LINK PINS + THE CHECKER THAT CRIED WOLF
([#659](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/659), squash `e21b4fd5`), AND ALL
FOURTEEN ARE LIVE.** Verified against the **live sources**, not the workflow's success line: the
Supabase RPC (what the app reads first) and the gh-pages mirror each serve **256 link pins**, with
**0 pins wrongly inside `tours`** and `priceTier` / `isPrivate` both intact.

✅ **MERGED — FOURTEEN LINK PINS + THE CHECKER THAT CRIED WOLF
([#659](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/659), `claude/tour-links-upload-3bqlib`).**
Fourteen links from the owner — 13 TikToks + 1 Instagram reel, **all alive, nothing parked**.
**linkPins 242 → 256 · makers 188 → 191 · New Zealand the 37th country** (re-derived after [#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658) merged under it; the PR body's 244 → 258 was measured against the older base). Then, on owner
instruction (*"fix the checker"*), the tooling half: **`check-image-duplicates.py` was hashing error
pages and caching them**, so two URLs failing the same way became a permanent false "duplicate" — it
reported two unrelated pins as byte-identical when they are not. `download()` now reads the status
code (a 200 is the only success), `looks_like_image()` gates the hasher, nothing failing either is
cached, and the cache dir moved to `.cache/image-dupes-v2/` because a poisoned entry is
indistinguishable from a good one. **Content + tooling + docs, no Swift — auto-merge on green.**
✅ **MERGED — LA CLEANUP: TWO DUPLICATE PINS PULLED, FOUR LA PLACES BUILT
([#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658), squash `2a222899`), AND ITS SQL
HAS BEEN RUN.**
Owner instructions: remove one of the two Hotel Casa del Mar pins and its place page, take out the
YouTube Castle Green, then *"make bradbury, griffith and union station places. make petersen also a
place, and go with your recommended coordinate."* **linkPins 244 → 242 · makers 189 → 188 · places
41 → 40 → 44 · tours unchanged at 1,552.** Content + one SQL file; no Swift, no build.
**✅ `backend/pull_la_duplicates_260830.sql` HAS BEEN RUN (owner, 2026-08-30) and nothing is owed** —
re-read from the **live RPC** rather than the SQL Editor's success line: all four deleted rows gone,
all three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` (66 priced) and `isPrivate` both intact. **The four places needed no SQL** — the
seed carries them, so they arrived with the merge. **The pin moved and the tour did not — verified by diff: 0 Atlas tours changed a coordinate,
trigger mode or radius.** Every place hero is a **third photograph promoted from the member tour's
own gallery**, nothing sourced.

✅ **MERGED — THE DUPLICATE-IMAGE CHECKER HAD NEVER SEEN A LINK PIN
([#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657), `claude/tour-links-upload-qeoxe7`),
squash `597b5aff`.**
Owner: *"do it now if it helps."* `scripts/check-image-duplicates.py` reads `catalog["tours"]` and
nothing else, so **all 244 link-pin heroes were invisible to it, `--all` included**, from the day
#597 split them into a sibling `linkPins` array. Measured before the fix: **`--all` saw 5,595 images
and 0 of the 240 pin heroes.** Tooling + docs only — no catalogue change, no Swift, no SQL — so this
is the **auto-merge class**: merge on green, no owner gate. ⚠️ **The catalogue is clean, and that is
now measured** (5,835 images, 0 errors, 27 INFO, 0 fetch failures) rather than assumed — my first
description of this to the owner called it a convenience gap and said nothing was wrong because of
it, which was not something I had checked. Adds **`--pins`**; **`--maker <CODE>` stays tours-only
deliberately**, because pinned handles collide with city codes as substrings (`STO` matches
`@urbanstoriesyt`; 31 collisions catalogue-wide).


✅ **MERGED — FIVE ARCHITECTS JOIN THE VOCABULARY
([#654](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/654), squash `f93321b6`).** `Moshe
Safdie` · `John Augustus Roebling` · `William Henry Barlow` · `KieranTimberlake` · `José Ignacio
Linazasoro`. **⚠️ IT MERGED *AFTER* THE PORTMAN PR ([#655](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/655), `0086a212`) THOUGH IT WAS BRANCHED BEFORE IT** — the case where one
session's vocabulary edit silently reverts another's. **Checked rather than assumed, on `main`:
Portman survived, 330 + 5 = 335 architects / 385 tags, and the two copies of the vocabulary agree
exactly** (`Models/Tag.swift` and `scripts/validate-tours.swift` — a mismatch produces an error per
tagged entry). Validator mirror: **0 errors, 2 warnings across 1,552 tours + 244 pins + 41 places**,
both pre-existing; **0 unused names**, and **0 of the 497 named-architect entries missing `Designed
by a Master`**. ⚠️ **Still never compiled or seen in a simulator** — it is a `Models/Tag.swift`
change and CI's build is the only check it has had.

✅ **THE `@nycunfilteredstories` REMOVAL SQL HAS BEEN RUN (2026-08-30).** Owner applied
`backend/pull_nycunfilteredstories.sql`; verified against the live RPC — all four pins and both
creator rows gone, 0 pins wrongly inside `tours`. **Nothing owed; do not ask again.**

✅ **THE LINK-PIN FULLSCREEN BUG IS FIXED, SHIPPED AND OWNER-VERIFIED.**
[#622](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/622) squash `e22dba7`, **build 134 from
`main`**. Owner on the probe build carrying the same fix: *"133 is live. that seem to be done the
trick."* **Nothing is open from this work; the story moves to `CLAUDE.md` § Current State.**

- **🔴 IT TOOK FOUR BUILDS AND THREE WRONG DIAGNOSES, and this board carried two of them as fact.**
  #611 (build 129) and #617 (build 130) both shipped as "the fix" and neither was. **TikTok and
  YouTube embeds do not use WebKit element fullscreen at all** — the video takes its **own
  `UIWindow`**, at or below `.normal + 1`, which is where the module window lives. `fullscreenState`
  never changed, so nothing ever fired. **Never record a fix as verified on the strength of a merge.**
- **⚠️ The probe branch `claude/link-fullscreen-probe` is still on the remote and was never merged**
  — builds 131/132/133 came from it. **Owner must delete it in the GitHub UI**; the git proxy blocks
  branch deletion from a session. `grep TEMP-PROBE` on `main` is clean.

✅ **NINETEEN LINK PINS MERGED, ONE PULLED, AND THE PULL SQL IS APPLIED.**
[#638](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/638) squash `ce6ec46b` ·
[#641](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/641) squash `2f84df52` ·
[#642](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/642) (scratch files that rode in on a
`git add -A`). **This batch took linkPins 150 → 169 → 168 and makers 153 → 154.**

⚠️ **A PARALLEL SESSION'S [#640](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/640) LANDED
MINUTES LATER** (*"Thirty-two link pins, and the stack cap that demanded a place"*, squash
`cd32e293`), so read the counts above as **this batch's deltas, not the catalogue's totals**.
That session then closed itself out with two more merges — [#646](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/646)
squash `f172f07b` (**Jefferson Market Garden**, the one link it had parked for want of an
identifiable subject, wired on the owner's *"pretty sure it's jefferson market garden"*) and
[#647](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/647) squash `cec3aa39` (docs).

**`main` now carries 201 link pins · 184 makers · 38 places.** Pins and places were re-derived
from the **live Supabase RPC** after the last merge (201 · 38, confirmed); the maker figure is the
**catalogue's**, because ⚠️ **the RPC reports 194** — upsert-only accumulation plus real sign-ups,
long-standing and expected. **Assert on link-pin counts, not maker totals.** Both branches
auto-deleted. Its story is in
`CLAUDE.md` § Current State and `archive/HANDOFF-260829-2.md`. **Open PRs: [#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657) (tooling, auto-merge class) plus the architect-vocabulary PR above.**

- **✅ THE SWAN & DOLPHIN HERO IS SETTLED — the owner keeps it** (*"i'm fine with the swan dolphin
  hero"*, 2026-08-29). Its YouTube thumbnail is a dark, indecipherable frame and **no better one
  exists** — `maxresdefault` and `sddefault` both 404 on that upload. **A hero audit will flag it
  again; it is closed**, like the Royal Hospital Chelsea and Ministry of Enterprise heroes above.
- **⚠️ Two of the thirty-five links are dead at the source and cannot be recovered from this end** —
  each returns a ~215 KB embed shell with no owner blob on six spaced fetches, against ~257–262 KB
  with one for a live post. **Only the owner re-sharing live links fixes those.**

- **✅ `backend/pull_pins_260829.sql` HAS BEEN RUN and verified against the live RPC** — `linkPins`
  **168**, all five pins gone (the Instagram Zacherlhaus plus the four from 2026-08-28 that had
  never been removed from Postgres), both pulled creator rows gone, `places` still 37 and
  `priceTier` still on all 1,553 with 66 priced. **Nothing is owed on the backend.**
- **✅ THE LAST OWNER CALL IS CLOSED: the Royal Hospital Chelsea hero stays** — *"keep chelsea,
  i'm fine with it"* (2026-08-29), though its thumbnail is a podcast talking head with no view of
  the building. **A hero audit will flag it again; it is settled.** Nothing from this work is open.

✅ **COPENHAGEN AND THE DANISH ARCHITECTS BOTH MERGED AND VERIFIED LIVE (2026-08-26).**
[#615](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/615) squash `1e966661` ·
[#616](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/616) squash `5196e459`. Both branches
auto-deleted. **Nothing is open from this work and nothing is owed on the backend** — the story
moves to `CLAUDE.md` § Current State, per this file's own rule.

- **Verified against the LIVE RPC, not the merge:** Atlas Studio CPH 🇩🇰 serving all 40 tours,
  `country: Denmark` on 40, `places` still 27 and `priceTier` still emitted (no keys dropped).
  Architect tags landed too — `Henning Larsen` 0 → 2, `Designed by a Master` 449 → 466. The
  gh-pages mirror converged about seven minutes after Supabase.
- **⚠️ OWED — no simulator or device review of #616.** Owner approved the merge without one. The
  visible effect is 24 new architect names as filter chips and 21 tours joining the
  "Designed by a master" shelf; no layout change, and CI's simulator build + unit tests were green.
- **🔴 STILL UNRESOLVED: an ATLANTA batch is staged on gh-pages with no tracker row.** gh-pages
  `c533f3c4` (2026-08-24) pushed 41 Atlanta images while `drafts/AUDIO-PENDING-SURVEY.md` said the
  queue was empty. Flagged in the tracker; **whether scripts exist, and on which branch, was never
  established.** Do not report the queue empty without re-deriving.

---


---

## Finished sub-sections moved from STATUS.md

⚠️ Two of these were both numbered `1b` — a duplicate heading nobody noticed,
which is its own argument for keeping finished work out of a live board.

## 1b. Earlier board state (link pins)

**Eight PRs merged between 01:22 and 03:10. Zero are open.** The link-pin feature went from four
throwaway test pins to real content in under two hours.

✅ **BUILD 117 IS UP, FROM `main` AT `2a47e28`** — the tip itself, succeeded 03:33 with notes
attached. It carries #592 (the WALK pill below the metadata), which was the only merged app code not
in a build. **Nothing is stranded and nothing is open except the board PR below.**

🟡 **[#596](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/596) OPEN — this board, the contract
check and `restore_catalog_keys.sql` finally reach `main`.** All three had only ever existed on
`claude/project-tracking-dashboard-1kggmu`, so `CLAUDE.md`'s own session-start ritual
(`git show origin/main:STATUS.md`) has been 404ing for every parallel session. **Additive only: 5
files, +614, −0.** The branch was 41 commits behind, so `main` was merged in first and both conflicts
(`CLAUDE.md`, `backend/schema.sql`) resolved toward `main` — `schema.sql`'s newer warning is strictly
better, and rules 10/11 plus the 2026-08-20 block were re-added surgically.

✅ **THE TEST CREATORS ARE GONE — 49 makers → 45, verified against the live RPC.** Exactly the seven
real sign-ups remain, every one carrying a `user_id`. Places still 25, contract check passes.

**🔴 IT TOOK THREE PASTES, AND THE REASON IS WORTH KEEPING. THE TEST TOURS WERE TAKEN DOWN, NOT
DELETED.** Each of the four creators still owned one tour at `status = 'taken_down'` —
`takedown_tour()`, run in an earlier session. **A taken-down tour is invisible to every ordinary
read:** `get_catalog` serves published only, and so does the RLS policy behind PostgREST. So the
catalogue reported those creators had no tours, a direct API read agreed, and **both were wrong**.
Only a query run as `postgres` saw them.

- **⚠️ DURABLE RULE: anything reasoning about "does this maker have tours" must query the table as
  `postgres`.** Otherwise it is reading a filtered view and will conclude the exact opposite of the
  truth. The same applies to any tour count, any orphan check, any cleanup script.
- **⚠️ AND THE GUARD MADE IT INVISIBLE — the sharper lesson.** The first version's maker delete
  carried `not exists (select 1 from tours …)`, which the hidden rows failed, so the statement matched
  zero rows and reported *"Success. No rows returned."* **`tours.maker_id` is `on delete restrict`**,
  so without that guard Postgres would have raised a foreign-key violation naming the exact blocking
  row, and the answer would have arrived on the first paste. **A guard that turns a loud, specific
  error into silence is worse than no guard.**
- **⚠️ It could not be one statement:** `restrict` fires the moment the parent row goes, even when the
  child is being deleted alongside it. Tours first, then makers. `purchases.tour_id` is also
  `restrict`, so a tour that had ever been bought would raise rather than destroy the record of a sale.
- **The wider debt is unchanged and still real:** `seed_from_toursjson.py` is upsert-only, so nothing
  ever leaves the live database on its own. Every future removal needs a hand-written delete like
  this one. Worth fixing properly before launch.

## 1c. ✅ RESOLVED — build 66 can read the catalogue again

**Both fixes merged and are LIVE. Verified against both sources, not the PR descriptions.**

| | `tours` | `linkPins` | Build 66 decodes? |
|---|---|---|---|
| gh-pages mirror | 1,512, only `single`/`multiStop` | 4 | ✅ all of it |
| Supabase RPC | 1,513, only `single`/`multiStop` | 4 | ✅ all of it |

Top-level keys on both: `linkPins`, `makers`, `places`, `tours`. **Zero unfamiliar kinds inside
`tours`** — which is the whole test. Build 66 now catches up to the full catalogue on first launch
rather than freezing at its 1,350-tour August seed.

- **[#597](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/597)** — link pins move out of `tours`
  into their own top-level array, carried consistently through `Tours.json`, the gh-pages mirror
  (`publish-catalog.yml`), `seed_from_toursjson.py` and `get_catalog` (`backend/split_link_pins.sql`).
  New `LegacyCatalogCompatibilityTests` pins the guarantee.
- **[#598](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/598)** — per-field tolerance plus a
  tolerant array, and it **counts what it drops** rather than swallowing silently.

**🔴 WHY THIS WORKED AT ALL, and the rule to keep:** an unknown top-level KEY is free; an unknown
VALUE in a known field is fatal. `ToursData` uses synthesised `Codable`, which ignores keys it does
not know. Proven on this app before it was relied on: `sourceURL`, `sourceAuthor`, `country`,
`videoURLs` and `videoRole` were all added over time with no shipped build noticing. Nothing ever
broke until a new *value* appeared inside a field builds already parsed.

**⚠️ Tolerance could not have fixed this and must not be mistaken for the fix.** It protects only
builds shipped after it; build 66 is strict and always will be. The separate section is the only
thing that rescues an already-shipped build. Keep both — different jobs.

✅ **BUILD 118 IS LIVE, FROM `main` AT `d80465b`** — the tip itself. It is the first build that reads
`linkPins`, so the four creator pins reappear after being absent from 116 and 117. **The one-build
lag is closed and nothing merged is stranded.**

⚠️ **118 changed HOW THE CATALOGUE IS READ, so ordinary browsing is the real test** — home map, a few
cities, a walk, the library. A decode regression would not look like a decode regression; it would
look like content quietly missing.

⚠️ **Build 66's release decision is now the owner's, unblocked.** It can be released safely, or
replaced with something current. It is still eight days and three cities behind in what it ships in
the box; it just no longer stays that way.

⚠️ **A cloud session cannot be messaged from a web session** — `ListAgents` does not reach it and
`SendMessage` fails. A session briefed on tolerance only had to be archived and replaced rather than
corrected. **Brief a spawned cloud session completely up front.**

## 1b. ✅ RESOLVED — the catalog regression, fixed and verified

**Owner ran `backend/restore_catalog_keys.sql` 2026-08-20, and has since confirmed on device that
the place pages and capsule pins are back.** Verified against the live RPC as well, not just the
success message:

| | Before | After |
|---|---|---|
| `places` | absent | **25** ✅ |
| `priceTier` | absent on 1419 tours | present on 1419, **66 priced** ✅ |
| `isPrivate` | absent on 39 makers | present on **39** ✅ |
| `country` | 1418 | **1418** — held ✅ |
| `videoURLs` · `userId` | intact | intact ✅ |

All 25 places carry ≥2 tours, so every one renders. **`country` holding is the specific proof that
mattered** — re-running `places_apply.sql` instead would have restored places and knocked country
back out, which is why the separate file existed.

**Cause, for the record:** `add_country.sql` rebuilt `get_catalog()` from `schema.sql`'s body —
correctly, by its own design — but `schema.sql` had never carried `places`, `priceTier` or
`isPrivate`, all added by later migrations. Nothing errored; all three are optional in Swift, so
the features silently stopped existing. **Not a code fault, and not build 91's.**

**Hardened, two ways.** `schema.sql` now carries both missing keys plus a 🔴 warning that the
function is wrapped in production and every later key must be added there too. And there is now a
check that runs whether or not anyone is paying attention:

**`scripts/check-catalog-contract.py`** — queries the live RPC and diffs its key set against the
Swift models. The expected keys are **parsed out of `Models/Tour.swift`, `Maker.swift` and
`Place.swift`**, never hardcoded, so adding a field starts requiring it on the next run with no
edit to the script. A hardcoded list would drift and quietly stop testing anything, which is the
exact class of bug it exists to catch.

**It works: its first run found a fourth missing key nobody knew about** — `tours[].createdAt`.
That one is **pre-existing, not a regression** (the RPC has never served it). `Place.ranked` sorts
NEWEST FIRST on it, so that rule has no dates to sort on and falls through to its tiebreaks.
⚠️ **Do not "fix" it by emitting `tours.created_at`** — that column is `default now()` and the seed
never carries the authored date, so it holds *seed* time; most of the catalog shares 2026-06-27,
the original bulk seed. It would look fixed and rank wrongly. The real fix is to make
`seed_from_toursjson.py` carry the authored `createdAt` first. Recorded in the script as a **known
gap**: printed as a warning every run, but not a failure — a check that always fails gets ignored,
and then it catches nothing.

## 1d. ✅ DOZENT IS LIVE ON THE APP STORE

**Owner-reported 2026-08-28: approved by Apple and published.** Submitted 2026-08-18 03:22 UTC as
version 1.1 on **build 66**, `releaseType` MANUAL, so the owner pressed Release themselves. Ten
days from submission to live. **This is the first public release; every prior build was TestFlight.**

⚠️ **Not machine-verified from this session** — a remote container has no App Store Connect key
(`~/Downloads/AuthKey_*.p8` lives on the owner's Mac), so `scripts/session-start.sh` skips the
check here. The owner is the primary source and outranks any document; a local session should
confirm the live version/state from the API before quoting numbers back.

**🔴 WHAT CHANGES NOW, AND IT CHANGES THE STAKES OF EVERY CONTENT MERGE.** Until today a bad
catalogue reached TestFlight testers. It now reaches **App Store users on build 66**, which is a
strict decoder frozen at 18 August:

- **Build 66 has no tolerance layer.** [#598](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/598)'s
  per-field fallbacks and tolerant array **only protect builds shipped after it**. On 66, one
  unfamiliar value inside a known field still fails the whole catalogue decode, silently, and the
  phone keeps its last good copy forever.
- **What saves it is [#597](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/597)** — link pins
  travel in their own `linkPins` array, which 66 ignores as an unknown key. **That split is now
  load-bearing for a shipped App Store build. Never put a `kind: "link"` row back inside `tours`.**
- **The three guards that enforce it must stay green**: `scripts/check-catalog-keys.py`,
  `publish-catalog.yml`'s mirror refusal, and `validate-tours.swift`.
- ⚠️ **Build 66 bundles 1,350 tours against 1,552 live** — it catches up on first launch from
  Supabase, which is exactly the path the split protects.

**Owed, and worth doing before the next release:** ship an update, because every fix since
18 August — the launch sequence, offline photographs, fullscreen video, the search rewrite, the
link-pin fullscreen fix — is **not** in what the public has.

**✅ THE UPDATE IS PREPPED (2026-08-31).** `fastlane/metadata/en-US/release_notes.txt` is written
(required for an update, impossible on a first release — which is why it had been deleted), the
description's stale counts are corrected and its two missing features added, and
`docs/launch-runbook.md` gained a **§ Shipping an update** with the two rules that only bite on an
update: What's New is mandatory, and the version must be new (**`MARKETING_VERSION` is 1.1.1**,
because Apple refuses builds against a released 1.1).

- **The build is ready: 137**, owner device-verified. Its app code was diffed against `main` and
  differs by **one comment block**; only its bundled seed is behind, which catches up on first
  launch. **No new build is needed.**
- **🔴 VERIFIED AGAINST BUILD 66'S OWN SOURCE, not assumed:** its `ToursData` decodes
  `{makers, tours}` only and the tree carries **no `Models/Place.swift`** — so **every one of the
  283 link pins and 49 place pages is invisible to the public today.** That is the split working as
  designed, and it makes both the headline of the release notes.
- **⚠️ Remaining steps are owner-only and outside the repo:** create the 1.1.1 version record, push
  the metadata, attach build 137, submit. § Shipping an update has them in order.

### ✅ 1.1.1 SHIPPED — the block above is finished, and the board did not say so for a week

**Machine-verified 2026-09-08, not owner-reported: `version 1.1.1`, `currentVersionReleaseDate
2026-09-01T15:23:09Z`.** It went out on **build 139**, not the 137 named above — 1.1.1 was first
submitted with all eleven pending IAP tiers, **rejected under Guideline 2.1(b)** because no tour was
priced at any of them, then cancelled and **resubmitted version-only** on 1 Sep. The eleven tiers are
parked at `READY_TO_SUBMIT`; the rule that came out of it is in `docs/lessons.md` — *a tier is only
real once content uses it.*

🔴 **This board carried "remaining steps are owner-only" for a week after the app was live, and every
session that read it inherited the error.** The check that settles it takes one command and **needs
no App Store Connect key**, so no session ever had an excuse:

```bash
curl -s "https://itunes.apple.com/lookup?bundleId=com.ehky.TRAVEL-GUIDED-TOUR&country=us" \
  | python3 -c 'import json,sys; r=json.load(sys.stdin)["results"][0]; print(r["version"], r["currentVersionReleaseDate"])'
```

`scripts/session-start.sh` now runs it on every session, so a keyless container no longer has to
say "I could not check the App Store version" — **only an UNRELEASED version's review state still
needs the key.** The perishable-facts table in `CLAUDE.md` is corrected to match.

⚠️ **A second keyless signal, already on this board and not read as one:** build 140 was rejected at
upload with **90186 `Invalid Pre-Release Train`**. A train closes when Apple approves the version —
so that rejection was itself proof 1.1.1 had shipped, five days before anyone said so.

**What the public has now, and what it does not:**

| | |
|---|---|
| Released | **1.1.1 (build 139)**, 1 Sep 2026 |
| `MARKETING_VERSION` on `main` | **1.1.2** — the next update's train is already open |
| Code on `main` the public lacks | **[#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728) only** — the bottom module going missing. Owner-verified on TestFlight 1.1.2 (141). Everything else since 1 Sep is catalogue, which reaches 1.1.1 over the air |
| Catalogue the public DOES get | 1.1.1 understands `linkPins` and `places`, so every pin and place is live to them — the thing build 66 could not see. (**1,426 pins / 130 places** when measured; it grows daily, so re-derive) |

**⚠️ The map expand control shipped in 1.1.1 and its release notes never mention it.** The notes are
published and frozen, so that is permanent; the feature is simply undocumented to the public. **Do
not "fix" it by editing `release_notes.txt` now** — see § Shipping an update, which the same commit
corrects: those notes describe the delta from the **last released** version, so the next edit to that
file is a rewrite for 1.1.2, not an amendment to 1.1.1's.


---

### #777 — 61 @urbanistariel link pins (session 152, merged 2026-09-09)

🟡 **OPEN — [#777](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/777) — sixty-one `@urbanistariel` link pins (session 152, 2026-09-09).** The owner sent 62 TikTok links; **61 ship, 1 is held back** — `7255575696582446378` ("buildings that look like the Parthenon — they're everywhere") arrived with no location and has none, and overlaps in subject with the live **The Parthenon** pin from 8 Sep. **linkPins 1,489 → 1,550 · `tours`, `makers` and `places` byte-identical** (the creator's maker row already existed and is reused). **Greece is the story: 28 pins, the catalogue's first real Greek cluster** — Athens 14, Mystras 2, Ancient Messene 2, Mykonos 2, Filiatra 2, plus Chania, Sparti, Nafplio, Megara, Pyrgos Dirou, Gytheio. Then NYC-area 13, France 9, Puerto Rico 5, Germany 5, Edinburgh 1. Content only — **auto-merge class**, squash on green CI.
  - 🔴 **The two `Lower Town, Greece` Plus Codes are Mystras, not Monemvasia — a naive recovery put both 88 km out, in the Myrtoan Sea.** A short Plus Code recovers against a *reference point*, so the reference decides the answer; "Lower Town" read as Monemvasia, a real Peloponnesian lower town. Both captions name Mystras outright. **This is the class of defect nothing downstream catches** — validator passes, CI compiles, every URL 200s, and the pin never fires. Caught only by reading each coordinate back against its own caption, which is now the habit worth keeping for any Plus Code batch.
  - ⚠️ **`castillo-san-felipe-del-morro-urbanistariel_hero.webp` already existed on gh-pages** with different bytes and **no catalogue reference** — an orphan. Published as `...-2-urbanistariel_hero.webp` rather than overwriting a live URL.
  - ⚠️ **Two titles clashed with pins already live from the same creator** and were disambiguated rather than shipped as twins: **The Parthenon: The Missing Roof** and **Central Park: How It Was Designed**.
  - ⚠️ **`check-image-duplicates.py --pins` exited 0 on its FIRST run having 404'd all 61 new heroes** — GitHub Pages had not deployed them yet. That verdict covered nothing. **Re-run after the deploy: 1,543 images fetched, 0 failures, no duplicates** (stamp `2026-09-09T12:16:21Z`). A clean verdict from a checker that fetched nothing is exactly the trap in `CLAUDE.md` § Reading a check's result.
  - ⚠️ **No sourceURL overlap with the open #749** — verified link by link against that branch's catalogue; the two batches are disjoint. #749 remains conflicted and 1,390 pins behind.


---

### The last @urbanistariel link, placed (session 152, 2026-09-09)

🟡 **OWNER OWED — one link from the `@urbanistariel` batch has nowhere to go ([#777](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/777) MERGED, squash `f73beb25`, 2026-09-09).** 61 of 62 links shipped; **linkPins 1,489 → 1,550**, Greece 7 → 35. The holdout is `https://www.tiktok.com/@urbanistariel/video/7255575696582446378` — *"buildings that look like the Parthenon — they're everywhere"* — which arrived with no location **and has none**: it is about neoclassical architecture worldwide, not a place, and it overlaps in subject with the live **The Parthenon** pin from 8 Sep. **The owner names a coordinate or it is dropped.** Everything else is wired, seeded and serving.
  - ✅ Verified after the merge: Supabase snapshot rebuilt at **2026-09-09T12:38:22Z** (the merge's own seed), `tours` rows **3,103** (= 1,552 tours + 1,550 pins + the same 1-row offset this query has always carried), gh-pages mirror **1,552 tours + 1,550 pins**.
  - 🔴 **The durable finding is in `docs/lessons.md` § 4: a short Plus Code recovers against its reference, so a vague locality is an unresolved reference, not a place name.** Two codes labelled `Lower Town, Greece` recovered **88 km out, into the Myrtoan Sea**; both captions said Mystras. Validator, CI and every URL were green throughout — the pin would simply never have fired.
  - Full account: `archive/HANDOFF-260909-4.md`.

---

## Moved out 2026-09-12

Both had MERGED and were still labelled `OPEN` in § 1 — the same failure this file's
header already records four instances of. Verbatim, unedited.

**⚠️ #795's own entry asks for an SQL paste. That paste HAS since happened** — checked
against the live RPC on 2026-09-12: stop objects come back carrying
`id, order, title, caption, audioURL, imageURL, latitude, longitude, triggerMode,
triggerRadiusMeters, audioDurationSeconds` and **no `transcriptText`**. Read the check,
not the entry.

🔴 **OPEN — [#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795) — transcripts off the wire: catalogue −37.5% (session 153, 2026-09-10). OWNER SQL PASTE OWED.** Second Supabase notice: **11.82 GB against 5 GB, grace period cut to 13 September**. The dashboard per-day breakdown is unambiguous — **100.0% PostgREST every day**; Storage 977 bytes, Auth ~30 KB, **Edge Functions absent entirely** (the 238,583 invocations are a red herring), and **MAU is 17**, so it is not the users.
  - **Paste `backend/drop_transcript_from_catalog.sql` into the SQL Editor.** Idempotent. ⚠️ **Its last line, `select public.refresh_catalog_snapshot();`, is load-bearing** — `get_catalog()` serves a stored snapshot, so redefining the builder alone reports success and changes nothing a phone can see.
  - `stops.transcriptText` = **1.105 MB of 2.945 MB gzipped, 37.5% of every billed byte**, measured on the LIVE payload; 1,924 stops, 3,768,989 characters. **No consumer screen has ever rendered it** (grep-verified: only `Models/Stop.swift` and the maker paths, and `MakerTourService` queries `stops` directly, not the RPC). Column untouched. `String?` in Swift → **reaches phones already in the field with no App Store release**.
  - **Daily scoreboard** (allowance ≈167 MB/day): 8 Sep **1,963 MB** → 9 Sep **493 MB** (#770 lands) → 10 Sep **241 MB**. −37.5% puts today at ~**151 MB**, under the line.
  - ⚠️ **Two figures this repo carried were RAW, not billed:** the saving is **37.5%, not 41%**, and **`longDescription` is 8.2% gzipped (not 18%) and IS used** — kept deliberately. CLAUDE.md now states: **egress is billed compressed, so measure compressed.**
  - Guard added: `check-catalog-keys.py` **`FORBIDDEN_STOP`** fails if the key ever returns (14/14 selftests); `check-catalog-contract.py` KNOWN_GAPS entry so the deliberate absence reads as a warning, not a regression.
  - 🔴 **Owner also advised to upgrade to Pro before 13 Sep** — the 11.82 GB is already spent and cannot be un-spent; this fix governs next cycle, not this one.

🔴 **OPEN — [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) — the filter row: a door and four chips (session 160, 2026-09-12). ON BUILD 145. NEVER COMPILED.**
  - **What to look at:** the row under the search bar reads `All · Format · Price · Dozents · Tags`. Each opens a panel; each panel is multi-select, shows a live count beside every option, and commits with a floating brass pill that says how many results the picks give. `All` is a **door, not a filter** — it never fills brass, and its badge counts the values switched on behind it.
  - ✅ **CI is green — run 2329 on `fc8ff92`: validator, simulator build, and 621 tests with 0 failures.** The count reconciles exactly against the working tree (621 test functions, 17 of them new), so nothing was silently skipped. Written with no Mac in session and compiled first time; **the simulator has still never been looked at**, so layout, panel heights and the floating pill are exactly what the device review is for.
  - **Format splits seven ways** — audio stop · audio walk · Instagram posts · Instagram Reels · TikTok · YouTube Shorts · YouTube videos — in each platform's own words (product names capitalised, generic words not). Shorts is **3 pins** and Instagram posts **9**, kept on owner decision because nothing else would select them.
  - **`Tags` is one chip for the whole vocabulary**, not five facet chips. 🔴 That was free: `Tag.matches` derives each tag's facet from a flat set, so the chip count is presentation and the combine rule never moved — **any within a group, all across groups** (D6).
  - 🔴 **Round 3 — a `.sheet` from the main window can never cover the bottom module, and HIDING the module is the WRONG fix.** The bars live in a `PassThroughWindow` at `windowLevel = .normal + 1`, so anything the main window presents goes behind them. Round 1 withdrew them while a panel was up; the owner filmed the result and the frames are unambiguous — **the module vanished in one frame and the sheet's top edge did not enter for another ~130 ms**, so the transition ran map → hole → sheet. 🔴 **`BottomModuleRoot` already carried the answer, from session 24 with `PlayerView`: present from THAT window instead.** Done, which required moving `filter` off `HomeSharedState` (`ContentView`'s, so main-window-only) onto **`AppSharedState`**, the state both windows see. **`hidesBottomModule` is back to two owners** and the whole withdrawal path is deleted — 99 lines added, 104 removed. Lesson in `docs/lessons.md` § 9. Build **150**.
  - 🔴 **Round 2, and it settles panel heights for good: on iOS 26 a PARTIAL-height sheet is DRAWN as a floating card** — inset sides, bottom corners pulled into the display's curve, Liquid Glass behind it — and a sheet attaches to the screen's sides and bottom only at the **large** detent. Owner: *"the only thing that should ever [be] 'floating' is the bottom module."* So every panel is `.presentationDetents([.large])` and the five fractions are gone; `presentationBackground` now paints the panel colour full-bleed, which the inner `.background` could never do (content is safe-area inset, so a strip of system material sat along the bottom). ⚠️ **A `.fraction` detent is not a height knob on iOS 26.** Build **148**.
  - **Round 1 of device review is in, and build 146 carries the fixes** (`b4dfb511`). Five notes, four of them spacing; the fifth was an architecture collision worth knowing about — 🔴 **a `.sheet` cannot cover the bottom module by default.** The mini-player and tab bar live in a separate `UIWindow` at `.normal + 1`, installed so that UIKit modals pass *behind* the persistent player (Apple Music's architecture), so the module painted over the bottom 126 pt of every panel and took the commit pill with it. The panels now withdraw the bars while up, as the wizard and the link-pin fullscreen already do. ⚠️ **`hidesBottomModule` is a Bool, not a count — this is its third owner, and anything added later must re-check that none can overlap.**
  - ⚠️ **A push from a web session does not reliably start CI on an open PR**, so run 2329's green was on `fc8ff92` and the round-1 commit sat unverified until CI was dispatched by hand as run **2330**. `ci.yml`'s own header warns of this and carries `workflow_dispatch` for it. 🔴 **Read the run list against the head being merged — a PR can show green from an older commit.**
  - **Nothing merges until the owner has it on a device.** `Features/Home/*.swift`, `Models/*.swift` and `Theme/*.swift` are all in the code boundary, so this waits for an explicit OK.

---

## Moved out 2026-09-13 — the restructure that ended the conflicts

`STATUS.md` was one file every parallel session prepended to, at the same three
line numbers. **67 commits touched it in the seven days before this**, and three
pull requests in two days were blocked by a conflict in it — **#776**, **#820**
and **#843** — none of them a disagreement about code. Live state now lives one
file per entry under `status/`, where two sessions writing at once cannot
collide. See `scripts/status.py`.

Moved here verbatim, nothing deleted:

* **the `Last verified` / `Previously` chain** — 14 dated entries, 25 KB, in a
  file whose own header said *"What this file is NOT. History."*
* **§ 3's build table** — superseded by `status/builds/<number>.md`
* **§ 4's branch table** — 34 KB, and **deleted rather than migrated**: it was a
  hand-maintained copy of what `scripts/session-start.sh` already derives from
  git on every run, so it was stale the moment it was written.
* **§ 1 and § 2's finished items** — the still-open ones became
  `status/owner/*.md`.

### The header chain

# STATUS — the live board

**What this file is.** A short, mechanical record of *what is in flight right now*: open PRs,
which TestFlight build carries which branch, and what is waiting on the owner. It is the thing
a session reads to answer "what is everyone else doing?" before it starts work.

**What this file is NOT.** History. `CLAUDE.md` § Current State is the narrative record of what
shipped and why, and it stays the authority for anything already merged. When an item here is
finished, it leaves this file and its story goes there. Never let this file grow a history
section — two histories drift, and drift is the problem this file exists to fix.

**Update rule (automatic, no prompting).** Any session that opens or merges a PR, dispatches a
TestFlight build, or discovers/clears an owner-blocked item updates the relevant table here in
the same commit. Re-derive rather than trust: `gh pr list --state open`, and read the build
numbers back from the Actions run list — never from what a PR body predicted.

**Last verified:** 2026-09-12, 23:15 UTC ([#842](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/842) **OPEN, CI running** — 86 link pins from a 145-link triage of `@blessedarch` (an architecture account; 3 turned out to be `@__dreamspaces`), read by hand and reverse-geocoded before anything was minted; the full triage was published as an artifact and reviewed with the owner first. 65 architecture · 11 culturalHeritage · 8 sacredSites · 1 natureAndParks · 1 hiddenGems. **One duplicate caught after minting, not before:** "23-24 Leinster Gardens" (fake house facades, London) was already pinned via a `@blessedarch` TikTok post — the URL-only LIVE check in `triage-account.py` didn't catch it because this batch's post was the same subject on Instagram, a different URL; dropped before merging. Several posts deliberately hid their location ("can you guess where this is") — the STC Building (Jawahar Vyapar Bhawan, New Delhi), the LIC Building (Jeevan Bharati), Palika Kendra (NDMC HQ), Tagore Theatre (Chandigarh), Doha's General Post Office, and a "Pink concrete" post identified from its own Google Earth reveal-shot thumbnail as the Marin County Civic Center — all resolved via web research rather than skipped. **26 more candidates from the same triage are deliberately NOT in this PR:** Nominatim only found a city centroid for them, not the actual venue, and a wrong coordinate is invisible to every other check. A manhole-cover pin was considered and the owner rejected the only verified-still-existing example (a museum piece) — not minted. `validate-tours-mirror.py`: 0 errors, 3 pre-existing warnings unrelated to this batch. Heroes pushed to `gh-pages`; CDN propagation and `check-image-duplicates.py --pins` still pending as this line is written.)

**Previously:** 2026-09-12, 22:00 UTC (**two corrections to this session's own findings, and a new owner requirement.**) 🔴 **I called 27 accounts "abandoned maker signups" and that was wrong twice over.** `handle_new_user()` creates a `makers` row for **every signup**, consumer or maker — an owner decision from 2026-07-05 that the Settings count depends on — so nothing was abandoned; and I counted their tours through the **anon, published-only view**, the exact trap `remove_test_creators.sql` was written about after two failed pastes, so the count may understate. **Owner decision, restated: never delete a user account — "0 tours doesn't mean anything"**, matching the standing 2026-08-25 decision this session had ignored. § 6 is rewritten and the real issue is narrower: Search lists every account holder as a creator, and two `isPrivate: true` makers are served regardless with `userId`, `avatarURL` and `bio`, a flag no consumer code reads. **New owner requirement in § 2: every user needs a unique username** — there is no handle column today and `display_name` has no unique constraint; recommended shape is a `handle` beside `display_name`, unique on `(platform, handle)`, **design doc not yet written.** Earlier: **[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776) MERGED** (`ae804f4f`) on owner OK — rebuilt on current `main` first, because its green was from 9 Sep against a base 58 commits stale; validator, simulator build and full suite green on `a8f5e36`. ⚠️ **It merged on CI alone, with no device check** — a weaker bar than this repo's norm for launch-path code, named rather than glossed.

**Previously:** 2026-09-12, 21:20 UTC (**the owner pasted the SQL — the two duplicate pins are gone.**) Verified four ways rather than taken on trust: row count **3,441 → 3,439**, both pin ids return empty, the orphaned `Instagram @pacificmodernism` maker row is gone (so the conditional delete fired and it held no other pins), and `catalog_snapshot_age()` reads **21:17:56 UTC** — the rebuild is what makes a paste reach a phone, so it is the check that matters. ✅ **Both TikTok replacements survive**; after a deletion the risk is losing the survivor, not the duplicate. § 2's item is marked cleared, with the process rule kept — **a merged PR that needs an owner paste is not finished; it moves to § 2** — because that is what let it sit live for two days. **Still open and waiting on the owner: [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776)**, which merges cleanly and needs an OK plus a two-minute device check.

**Previously:** 2026-09-12, 21:00 UTC (coordinator catch-up — **no content, no code; two findings and one merge**). `main` moved **58 commits** since this session last looked. Catalogue re-derived on `f76bfac`: **1,552 tours · 1,886 pins · 388 makers · 290 places · 1,924 tour stops (3,810 including one per pin) · 501 cities · 64 countries** — ⚠️ the `CLAUDE.md` Key-facts line read **1,870 / 387 / 499**, its **twenty-fifth** staleness, because [#834](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/834)'s 16 pins landed *after* the previous correction; counted and corrected. ✅ **[#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795)'s SQL HAS been applied** — proved against the live RPC, not read off a board: stop objects come back with **no `transcriptText`**, so the 37.5% cut is real and serving. 🔴 **But a different paste is still owed and was on NO board: [#805](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/805)'s removal SQL never ran**, so the two `@pacificmodernism` Instagram pins #804 replaced are **still live on the map beside their replacements** — found by diffing the `tours` table (3,441 rows) against `Tours.json` (3,438); see § 2. The third extra row is a **private in-app maker upload** and is correct. 🔴 **[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776) is no longer conflicted** — re-tested, merges clean; it has been waiting on the owner since 9 Sep and is the only item blocked specifically on them rather than on another session. [#798](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/798) (docs-only, China reachability) **merged** as `f76bfac` under Rule 4 after sitting two days; squash verified to carry both files. App Store re-checked from Apple: still **1.1.1**, released 1 Sep. Latest TestFlight build: **150**. Supabase snapshot rebuilt **17:37 UTC** by #834's own seed; `get_catalog` 200 at TTFB 1.58 s. **Merged since the last look, in brief:** #749 (the 54-pin batch that was stuck for a week), #795, #835 filter chips, a **places expansion 181 → 290** across #801/#806/#807/#809/#818/#822 with several real coordinate defects repaired, #785 (a link pin that cannot load now says so), and #825/#827 (the website says the app is out). **All egress probes this session used the cheap forms in `CLAUDE.md` § Egress**; the one full-catalogue read was capped at 600 KB by stopping the stream.)

**Previously:** 2026-09-12 (session 160 — **CODE, awaiting owner device review.** The home map's filter row is rebuilt: the flat eighteen-toggle tag row becomes **All · Format · Price · Dozents · Tags**, each chip opening a panel, every chip multi-select. Open as [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835), on **build 145** — ⚠️ **never compiled: this session has no Mac, so CI on the PR is the first honest check and the device is the second.** Designed in Claude Design first and iterated against the owner's AllTrails reference, ~30 artboards, spec of record in `docs/filter-chips-design.md`. 🔴 **The design nearly shipped with no Price chip on a false reading of `Tours.json`** — it reads `priceTier: nil` for every tour **and always will**, because `seed_from_toursjson.py` omits the column deliberately; the live DB has **66 paid tours** (all multiStop, $0.99), read with the 47-byte count query, never the 3.4 MB RPC. Live figures the taxonomy was cut against: **1,553 tours vs 1,888 pins** (1,235 TikTok · 634 Instagram · 19 YouTube) — and the pin count moved 1,796 → 1,888 **mid-session**, which is the re-derive rule arriving on schedule. Counts beside each option are **contextual, not global** (`Contemporary` matches 401 alone and **zero** alongside four other picks), which is the part most likely to ship subtly wrong and is where the 17 tests are weighted. Chip heights are one decision: **44 pt in the row** (Apple's minimum, one-handed while walking) and **32 pt in the panels inside a 48 pt frame**, because a thumb feels the pitch rather than the drawn height. **Sort on the drawer header is designed and deliberately NOT built** — the one open item.)

**Previously:** 2026-09-11 (session 159 — **infra/docs/website, no code.** **Stripe round 5 SUBMITTED**, the first response able to show a product: the Website URL is now the **App Store listing**, because four rounds of argument could not substitute for a reviewer being able to look at the thing. 🔴 **Two claims from rounds 1–4 had quietly become FALSE** — "no transactions processed" and "all content is first-party" — both true when written, which is what makes copying them forward dangerous; the new rule is in `docs/stripe-review.md`. 🔴 **That file existed only on an unmerged branch** until [#802](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/802), so this session nearly re-sent round 3's answer; [#823](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/823) recorded round 5 verbatim, **three boxes not two** — the form reused round 3's title exactly and grew a required field, caught only because the owner sent a screenshot. **Purchase evidence: 4 rows, 1 real sale, 3 sandbox — ✅ closing the session-79 ES256 risk** (real user tokens DO reach `record-purchase`); no Apple money is the payout threshold, not a bug. 🔴 **And `dozent.world` had said "Coming Soon" for eleven days** while the App Store gave it as the support URL — six places across three pages, including `/g/` twice, fixed and **verified live** in [#825](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/825) (badge bytes hash-matched against the CDN). Two owner items added below, both minor. ⚠️ **I overwrote another session's `HANDOFF-260911-3.md`** by checking for a free suffix before fetching — restored intact from `origin/main`; the tell was `git status` showing `M`, not `A`.)

**Previously:** 2026-09-11 (session 158 — **[#811](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/811) MERGED** (squash `2208a76`): `scripts/triage-account.py` plus the triage step written into `docs/link-pin-runbook.md` and `.claude/skills/atlas-upload/SKILL.md`, and six link pins from TikTok `@jamiepeva`. Catalogue re-derived on the base carrying `ca2e449`: **1,552 tours · 1,794 pins · 384 makers · 266 places · 486 cities · 64 countries** — ⚠️ `main` moved twice around this work (#810 mid-flight, and `places` 250 → 266 *after* the merge), so the Key-facts line went stale for the twenty-third time — and then a twenty-fourth, inside the very PR correcting it, when #814 and #815 landed during an 18-minute simulator build. Counted and corrected against the base actually being merged. A creator's account is no longer minted unread: the tool flags LIVE / SINGLE / MULTI / THIN / DEAD and mints nothing. 🔴 **The flags are a pre-sort, not a verdict** — measured both ways in one run on `@jamiepeva`: 9 of 11 posts passed as SINGLE where **3** were pinnable, *and* a post captioned `📍 Mount Vernon, Virginia` was binned as non-place content. Enumeration ceilings measured rather than assumed: TikTok **14** from `/embed/@handle` (the profile page is captcha-walled — 371 KB, zero ids; a cursor does not deepen it), YouTube ~15 via RSS, **Instagram nothing at all — Basic Display died Dec 2024 and no third-party post-listing route exists**. `validate-tours-mirror.py` 0/0 with 32/32 faults caught; `check-image-duplicates.py --pins` clean and its count reconciled exactly; hero bytes hash-matched **7/7 against the live CDN** after the Pages rebuild. **Supabase seeded automatically** — `publish-catalog.yml`'s seed job ran and the live DB was checked directly (6/6 rows, snapshot 13:27 UTC, via the 34-byte `catalog_snapshot_age()` rather than pulling the catalogue). **No owner SQL owed.** **One owner decision recorded: property-listing videos are judged case by case** — the creator is a Georgetown estate agent as well as a historian. Two non-blocking items left open, in the handoff: the **Castillo San Felipe del Morro** half-finished hero correction (hero repointed to `-2`, its stop still on the original file), and one image that failed to fetch during the scan — unverified, not passed.)

**Previously:** 2026-09-11 (29 link pins from TikTok `@thedesignssuite` / `@vamuseum` / `@tate` — London architecture and housing estates — MERGED as [#810](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/810) (squash `ddba8ba`). **23 new subjects; 6 stack as a second creator's take on a building that already has an Atlas tour or pin (owner instruction): Lloyd's Building, Tate Modern, Habitat 67, Walden 7, the Barbican, Trellick Tower.** Coordinates: the owner's own Plus Codes decoded with `scripts/decode-plus-code.py` where given, else geocoded fresh from the caption's named subject — every one then reverse-geocoded (Photon + Nominatim) to confirm what's actually there before wiring it in. Two needed extra legwork: **Whittington Estate** (Plus Code recovers onto "Lulot Gardens, Whittington Estate" directly, confirmed via Nominatim) and **Samuda Estate** (caption said "Summerhouse" — that's Netflix *Top Boy*'s fictional estate name; the real building filmed since 2019 is the Samuda Estate, Cubitt Town). `validate-tours-mirror.py` 0 errors/0 warnings — 1,552 tours + 1,773 pins + 250 places. `check-image-duplicates.py --pins` clean. All 32 hero/avatar images pushed to gh-pages in one commit (`gh` CLI unavailable in this session — built via git plumbing: `git hash-object` + `git mktree --missing` + `git commit-tree` against a blobless partial clone, so the ~2GB of existing images was never downloaded) and confirmed byte-identical against the live CDN after the Pages rebuild. `publish-catalog.yml` run 223 confirmed both destinations post-merge: gh-pages mirror at 1,773 pins, live Supabase `get_catalog` RPC sampled directly at 1,775 (two more landed from a parallel session in between) with the new titles present. No owner decision owed.)

**Previously:** 2026-09-10 (session 156 — 21 link pins from TikTok `@nickcabotrodriguez` MERGED as [#790](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/790) (squash `8450c9a`), on top of #789's base. Catalogue re-derived: **1,552 tours · 1,700 pins · 376 makers · 141 places · 466 cities · 64 countries**. Coordinates decoded from Plus Codes and reverse-geocoded, then every subject re-checked against the post's own thumbnail — several corrected an initial geocoded guess (a generic "Hollywood building" was the **Hollywood Pacific Theatre**; a "Madison Avenue restaurant" is **E.A.T.**). `validate-tours-mirror.py` 0/0, `check-image-duplicates.py --pins` clean once gh-pages (`b600496`) deployed. **Two owner decisions owed, both `check-place-candidates.py` finds, neither blocking:** (1) two of the 21 pins ("Part 5"/"Part 6") are the exact same coordinate — **First National Bank of Hollywood**, keep as two pins or make a place? (2) this batch's **St. Vincent de Paul Church** pin sits 12m from an existing Instagram pin for the same church — same call. **The owner also asked to hold an "Abandoned" tag** — a durable vocabulary change (`Tag.swift` + `scripts/seed_tags.py` + `docs/tag-taxonomy-v2.md`), not done in this content-only PR — until that ships separately; 12 of the 21 pins would use it.)

**Previously:** 2026-09-10 (session 155 — 35 link pins open as [#789](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/789); catalogue re-derived after resolving onto `887a8a7`: **1,552 tours · 1,679 pins · 376 makers · 141 places · 466 cities · 64 countries** — ⚠️ `main` moved twice during this session (#787, and #784 landing 27 pins), so the `CLAUDE.md` Key-facts line and this board's previous reading were both stale before the work began; re-derived, never quoted. Two owner decisions owed, in § 5.)

**Previously:** 2026-09-09 (session 153 — 37 link pins open as [#782](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/782); catalogue re-derived on `57e71cb`: **1,552 tours · 1,588 pins · 353 makers · 141 places · 447 cities · 63 countries** — ⚠️ the `CLAUDE.md` Key-facts line read 1,551 / 442, its twenty-first staleness, counted and corrected. One owner decision owed, in § 4.)

**Previously:** 2026-09-09 (session 149, second pass — a catch-up, no content. **`main` moved 11 commits overnight.** Catalogue re-derived on `d7254ab1`: **1,552 tours · 1,489 pins · 353 makers · 140 places · 427 cities · 63 countries** — ⚠️ **#769 added three places and left the `CLAUDE.md` Key-facts line reading 137, its twentieth staleness; counted and corrected.** App Store re-checked from Apple: still **1.1.1**, released 1 Sep. 🔴 **The Supabase over-quota email was our own tooling and the biggest line item was a check I added yesterday — owned in § 2 below, fixed by #770.** ⚠️ **My own 25–33% RPC failure figure now carries a correction** (§ SQL pastes owed): a cheap probe reads 12/12 today, but it is a *different request*, so neither number supersedes the other. 🔴 **TWO PRs ARE CONFLICTED AND STUCK, and one of them is the egress fix itself:** **#776** (the 34-byte version check — built, 8 tests, no owner SQL, needs owner OK + a two-minute device check because it touches `Data/*.swift`) and **#749** (54 pins, untouched since 8 Sep 13:55). ⚠️ **Neither will look broken** — a conflicted PR never triggers CI here, so both show no checks rather than a failure.)

**Previously:** 2026-09-08 (session 149 — a catch-up pass, no content. **Two findings, both measured rather than read off this board.** (1) 🔴 **1.1.1 has been LIVE on the App Store since 1 Sep 15:23 UTC** and § 1d below said the opposite for a week — machine-verified from Apple's *public* lookup endpoint, which needs **no App Store Connect key**, so no session ever had an excuse; `scripts/session-start.sh` now runs it on every start and the perishable-facts table in `CLAUDE.md` is split into released-vs-unreleased. (2) ⚠️ **The catalog RPC is failing far more than the ~1-in-8 recorded below** — see § SQL pastes owed for the fresh sample. Catalogue re-derived on `68d03a67` **after #758 merged mid-session**: **1,552 tours · 1,426 pins · 353 makers · 130 places · 414 cities · 61 countries** — ⚠️ **#758 landed 83 pins and left the `CLAUDE.md` Key-facts line reading 1,343 / 404 / 59, its nineteenth staleness, so this session counted and corrected it.** The gh-pages mirror was byte-current with `main` when measured. Open PRs: **#749** only, another session's link-pin batch.)

**Previously:** 2026-09-07 (session 147 — **the `@poche_space` pin now moves onto the Gilder Center on owner instruction, open as [#746](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/746): Gilder 3 → 4 members, AMNH 6 → 5. It also closes a REAL blind spot in `validate-tours-mirror.py` — `validate-tours.swift:553-554` errors when a `kind: "link"` stop is not `manual` and the mirror checked nowhere — found by injection and checked against the Swift before being called one.** ⚠️ **[#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743) merged while #746 sat open with green CI, so `Tours.json` conflicted and was resolved the documented way — main's file taken wholesale and the idempotent assembler re-run on it, never hand-resolved — with #743's Eastern State place asserted byte-identical afterwards.** Also session 146 continued — **[#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742) MERGED (squash `9eaabdd1`), so the catalog-materialisation SQL paste was unblocked — ✅ **and the owner has since applied it, so NO owner SQL paste is outstanding**; and **`Inside the Abandoned Eastern State Penitentiary` joined the existing Eastern State Penitentiary place as its third member** on owner instruction — the pin moved 3.8 m, the place did not. ✅ **THAT PASTE HAS SINCE HAPPENED, AND THIS HEADER SAID OTHERWISE FOR A DAY — corrected 2026-09-08 by [#750](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/750).** Every earlier reading here was honest when taken: #746 measured `catalog_snapshot_age()` and `get_catalog_built()` both returning **404 `PGRST202`** and `get_catalog()` **500 on three of three** — and #746 merged *after* [#748](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/748) had already corrected the body of this file, so the false claim outlived its own correction **in the header nobody re-read**. Re-measured live: `catalog_snapshot_age()` returns **200** with the snapshot rebuilt at **2026-09-08T03:20:30Z** (the seed from #746's own merge), and `get_catalog()` returned **200 on 3 of 3** at **TTFB 0.79–2.18 s** on a 10.6 MB payload. ⚠️ **`get_catalog_built()` still returning `57014` is the migration WORKING** — the slow builder runs once per seed and nothing serves it to a phone; see § SQL pastes owed. 🔴 **The durable lesson is § READ FIRST's own, paid for twice in one day: an owner-owed item can clear while a session is mid-flight, and a header is where a corrected fact goes to survive. Re-probe; never quote a live-system fact from this board.** ⚠️ **The seed's `refresh_catalog_snapshot()` call is guarded by `to_regprocedure`, so with the SQL unpasted it skips the refresh, raises a notice and still finishes GREEN — ask `catalog_snapshot_age()`, never a green seed job.** Earlier the same session — **both content PRs have MERGED and #744 is verified live: the Supabase RPC and the gh-pages mirror each serve 130 places with The Gilder Center present, its 3 members all on the place coordinate, 0 members off their place coordinate catalogue-wide and 0 link pins wrongly inside `tours`.** **The two: [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) made the Gilder Center a place (places 129 → 130, closing the last stack-cap finding from the Studio Gang batch), and [#745](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/745) added 28 link pins across 14 countries — eleven of them new to the catalogue, the largest expansion any batch has produced. #745 raises one owner decision: Griffith Observatory now sits exactly at `TourSetMap.maxStacked = 3` with no headroom.** ⚠️ **#744 claimed `archive/HANDOFF-260907.md` while #745's CI was running, so #745's handoff renumbered to `-2`, and both sides edited the Key-facts counts — re-derive rather than quoting them.** Earlier, session 146 — **the catalog RPC was found failing 4 calls in 12 with a statement timeout; the fix merged as #742 and carries an owner SQL paste that must come AFTER the merge**. Earlier the same day, session 145 — **[#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740) MERGED (squash `62b662b4`): four Miami/Little Rock places, catalogue now 129 places**, after a rebuild onto the `main` that session 146's [#739](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/739) had moved. Earlier, session 146 — **four places for the sites at the stack cap (Alcatraz · Hoover Dam · Fort Jefferson · the Leaning Tower of Niles), places 121 → 125, MERGED as #739**. Earlier the same day, session 144 — **41 link pins from TikTok `@itshistoryonair` MERGED as [#737](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/737)**, after [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738) moved `main` underneath it. ⚠️ **Re-derive catalogue counts rather than quoting them — three sessions shipped content the same day.**)

**⚠️ This board is no longer polled on a timer.** The coordinator session ran a 25-minute check
from 04:50 to 12:25 and found something worth reporting on two of fifteen ticks, at roughly 20k
tokens a tick — so it is now **on demand** (owner decision, 2026-08-20). It goes stale the moment
a parallel session merges something. **Re-derive before trusting it**, per the update rule above.

---


### § 3 — builds

## 3. Builds — which run number carries what

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** Read them back
after dispatching; never promise one in advance. And a build carries its branch's **merge-base**,
not `main` — GitHub reports a PR's base as main's current tip, which is misleading.

| Build | Branch | Carries | Result |
|---|---|---|---|
| **151** | `splash-breathing` | [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836) draw the splash first (`LaunchDeferredContent`), the zoom back to the solid disc on a rising bright breath, and `main` merged in — including #835's filter row (`6e7c3f3c`); branch current with `main`, version **1.1.2**. ⚠️ **151, not the next after 149** — the filter-chips session took 150; read back from the run | ✅ **VALID at Apple, and owner-verified on device — *"reviewed it. looks great!"*** (2026-09-12). Breathing starts right away, zoom solid; **#836 merged, squash `f669493c`** |
| **150** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) device-review round 3 — the panel is presented from the MODULE'S OWN WINDOW (`a2eec8c`) | ⏳ **dispatched 2026-09-12 20:01 UTC**, CI run 2338 alongside it. ⚠️ 150, not 149 — another session again took the number in between |
| **149** | `splash-breathing` | [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836) the timing fix — the breath's floor counts from the splash's first drawn frame, one full breath (`376461ec`); branch current with `main`, version **1.1.2**. ⚠️ Owner expected **148** — a parallel session had taken it; **149 read back from the run** | ✅ **VALID at Apple** (uploaded 2026-09-12 13:02 PDT). ⚠️ **Owner: breathing visible, but *"i had to wait a long time for it"*** — the static launch picture lingered because `ContentView` had to be built before the splash could draw. **Fixed on the branch** (`LaunchDeferredContent`). 🔴 149 also carries the washed-out zoom (since 147) — fixed on the branch too; next build not yet cut |
| **148** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) device-review round 2 — the panels span edge to edge (`609e4ef`) | ✅ **green (CI 2335 too), and owner-reviewed on device.** It produced one finding — the module visibly vanished ~130 ms BEFORE the sheet arrived — which 150 fixes. ⚠️ **148, not 147** — `run_number` is shared across branches and another session took 147 between dispatches. Exactly why the board's rule is to read the number back |
| **147** | `splash-breathing` | [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836) the splash circle breathes again, on Core Animation (`8f1db87f`); branch current with `main`, version **1.1.2** against a live 1.1.1 | 🔴 **VALID at Apple, but owner saw NO breathing on device** — *"i really dont see any breathing"*. Cause measured in the sim with timestamps: the gate's clock starts at mount, but the splash's first frame lands ~4.9s later (main thread building the app), so it drew for only **~0.77s** — one dip — before hand-off. Fix pending: start the floor at the splash's first drawn frame |
| **146** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) device-review round 1 — the panels now cover the bottom module, plus four spacing/layout fixes (`b4dfb511`) | ✅ **green, and owner-reviewed on device — *"it's good"*, with one further note** (nothing should float but the bottom module), which is what 148 carries. CI run 2330 green on the same commit |
| **145** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) the filter row: All · Format · Price · Dozents · Tags (`fc8ff92`) | ✅ **green — built, signed and uploaded 18:32 UTC; on TestFlight, awaiting owner device review.** It compiled **first time** despite never having been built in-session. Build notes attached at dispatch, so TestFlight carries them in *What to Test* |
| **143** | `creator-tours-china-visibility-wmnho7` | [#785](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/785) the link-pin embed failure state (`ef108754`) | ✅ **owner-verified — *"Build is live. I tested (not super extensively), think it works"*; #785 merged as `6a594081`.** ⚠️ Testing was the owner's own words *not super extensively*, so the false-positive case (the message appearing over a pin that works) is **watched, not proven** — see § 6 |
| **141** | `bottom-module-missing-45z6ep` | The same fix at **1.1.2** (`e6570bdc`) — 140's payload plus the version bump | ✅ **owner-verified — *"BUILD IS LIVE. MERGE"*; #728 merged as `4da52445`** |
| 140 | `bottom-module-missing-45z6ep` | [#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728) the bottom module was HIDDEN, not uninstalled, with `main` merged in (`b52315f8`) | 🔴 **rejected at upload — 1.1.1 is now APPROVED, so its train is closed** (90186 *"Invalid Pre-Release Train"* + 90062). ✅ **It compiled and signed cleanly** (`build_app` 219 s); only the upload step failed. **This is the documented per-release cost, and it is also the only signal a web session gets that 1.1.1 shipped** — a closed train means Apple approved it. Superseded by 141 |
| **138** | `map-expand-control` | [#671](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/671) the expand control on every inline map, `main` merged in (`e0799d8c`) | ✅ **owner-verified — *"LOOKS GOOD"*; #671 merged as `01c70f63`** |
| **137** | `instagram-player-fit` | #662 the Instagram crop + fullscreen scrubber, `main` merged in, **marketing version 1.1.1** | ✅ **owner-verified — *"works! thank you"*; #662 merged as `845f0d86`** |
| 136 | `instagram-player-fit` | Same code at **1.1** (`49ac5382`) | 🔴 **rejected at upload** — 1.1 is released, so Apple refuses the version string |
| **134** | **`main`** | #622 the real fullscreen fix — the video's own window (`e22dba7`) | ✅ **install this** |
| 133 | `link-fullscreen-probe` | Same fix + the temporary readout (`f6aaf78c`) | ✅ owner-verified — *"that seem to be done the trick"* |
| 132 | `link-fullscreen-probe` | `isElementFullscreenEnabled` theory + probe (`839d2296`) | 🔴 wrong theory — probe proved it |
| 131 | `link-fullscreen-probe` | The probe readout alone (`773727ae`) | ✅ diagnostic — this is what cracked it |
| 130 | **`main`** | #617 the `onDisappear` guard (`adbe3b94`) | 🔴 shipped as "the fix"; was not |
| 129 | **`main`** | #611 withdraw the module on `fullscreenState` (`8df37de8`) | 🔴 shipped as "the fix"; was not |
| 128 | **`main`** | Everything, from the tip (`43c9411a`) — functionally identical to 127 | ✅ superseded |
| 127 | `open-source-ai-integration-pxuxdh` | #605 search + map, merged as `43c9411` | ✅ superseded |
| 126 | `instagram-best-effort` | #606 Instagram, merged as `2ecb95a9` | ✅ owner-verified — superseded |
| 125 | `open-source-ai-integration-pxuxdh` | #605 search, branch caught up to `main` (`73364503`) | ✅ superseded |
| 124 | `open-source-ai-integration-pxuxdh` | Merged app code + #605's then-unmerged search work (`fc94f197`) | ✅ superseded |
| 123 | `open-source-ai-integration-pxuxdh` | Same work, earlier commit (`2f1784e9`) | ✅ superseded |
| 122 | **`main`** | #603 Instagram tap (`e106fd3e`) | ⚠️ carries the behaviour #604 withdrew |
| 121 | `new-task-i2k12e` | #601 list-page grid + sort (`33d2b0c4`) | ✅ owner-verified — *"121 went live. Looks good."* |
| 120 | `new-task-i2k12e` | #600 place-page grid + sort (`ad1ff15e`) | ✅ owner-verified — *"120 is live. works"* |
| 119 | `new-task-i2k12e` | Same work, one commit earlier (`8b4e6cdc`) | ✅ superseded |
| 118 | **`main`** | #597 link pins split out + #598 decode tolerance (`d80465b`) | ✅ superseded — owner-verified, pins visible |
| 117 | **`main`** | #592 WALK pill, on the real AMNH pins (`2a47e28`) | ✅ superseded — shows no link pins |
| 116 | **`main`** | #584 link pins + #585 YouTube/Short fixes (`233eb912`) | ✅ superseded — shows no link pins |
| 115 | **`main`** | #583 the stale hero fix (`8f5748b7`) | ✅ superseded — **un-frozen by #597** |
| 114 | **`main`** | Fullscreen video, Swedish architects, Akalla hero, `get_catalog` hardening (`8d2ad947`) | ✅ superseded |
| 113 | `chrome-row-modifier` | #576 chrome row extracted — head merged `main` at 13:14 (`e90d9995`) | ✅ superseded |
| 112 | `color-mismatch-elements-pj2ptt` | #573 chrome row made opaque | ✅ merged |
| 111 | **`main`** | #565 architects, #566 launch mark, #567 + #568 offline photographs (`891702fd`) | ✅ last true from-main build |
| 110 | **`main`** | Everything to 22 Aug, plus #563 light mode (`b421bde9`) | ✅ superseded |
| 109 | `launch-performance-animations-df4d7p` | #559 launch sequence (`52a86cfa`) | ✅ superseded by 110 |
| 108 | `launch-performance-animations-df4d7p` | Same work, one commit earlier | ⚠️ superseded |
| 98 | `wizard-comments-round2` | #558 wizard round two (`e0132c90`) | ✅ merged |
| 97 | `wizard-comments-round2` | Same work, one commit earlier | 🔴 **Live and installable, run shows RED, no notes** |
| 96 | `upload-wizard-improvements-ejopz3` | #552 the seven-step wizard | ✅ owner-verified — *"so much better"* |
| 95 | `ellipsis-button-consistency-vdorpi` | Became #555 — Liked on the shared list screen | ✅ merged |
| 94 | `ellipsis-button-consistency-vdorpi` | #553 list page as a layer | ✅ owner-verified, merged |
| 93 | `library-launch-jitter` | #549 Library launch jitter | ✅ merged |
| 91 | `main` | Wizard, Settings, list page, 5:4 heroes | ✅ owner-verified |
| 90 | `tour-upload-polish-qiliop` | #540 + the saved-tour hang fix | ✅ owner-verified — hang closed |

✅ **#552 merged `main` in before merging out** (`a9a3b32`, two real conflicts resolved by hand) — so
the stale-base warning this board carried against build 96 was dealt with by the session itself.



### § 4 — branches (hand-maintained; now derived from git instead)

## 4. Branches

| Branch | State |
|---|---|
| `claude/friendly-euler-l88a05` (2nd run) | **Open as [#820](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/820) — awaiting owner (touches `Features/Search/SearchView.swift`).** Bug found right after #815 merged: the owner searched for the new creators and saw **"0 tours"** on brand-new makers and a stale count on an existing one. Verified live `get_catalog()` directly first — the data was correct, all 15 pins present and correctly linked — so the bug is client-side. Root cause: `filteredMakers` reads `dataService.makers` live, but the "N tours" subtitle comes from `makerTourCounts`, built once in `buildIndexIfNeeded()` and only re-run from `.onAppear` — so a catalog refresh landing while Search is already open leaves counts frozen until the screen is fully closed and reopened. Fix: `.onChange(of: dataService.tours.count)` alongside the existing `.onAppear` call, same cheap size-guard. No unit-test coverage possible (`SearchResultsTests` only exercises the pure `SearchResults` struct, not view lifecycle) — verification is CI's simulator build + owner's device check, per policy for `Features/**/*.swift`. Restarted from `origin/main` after #815 (this branch's prior PR) had already merged — never stacked on merged history. **Re-merged onto `main` 2026-09-12 by the coordinator session; docs-only conflict.** |
| `claude/filtering-chip-system-htjq7k` | **Open as [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835)** — the filter row rebuilt: `TourFilter` (one Equatable value, four groups, the D6 combine rule, contextual counts) + `FilterChipRow` + `FilterPanels`, `TagFilterChipRow` deleted, `Tag.filterChips` → `Tag.panelGroups`, `LinkSource.isInstagramReel`, panel metrics in `AtlasSpacing`, 17 new tests. Spec: `docs/filter-chips-design.md`. **On build 145. Never compiled — CI is the first check.** Waiting on owner device review |
| `claude/optimistic-allen-lb09p8` | **Open as [#830](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/830)** — 7 link pins for TikTok `@kylewilliamdesign` + 1 for Instagram `@ninosbuildings`. The owner supplied 8 links with no coordinates; each was identified by caption (TikTok oEmbed) or, where the caption named nothing (both Instagram reels), by reverse-image-identifying the thumbnail, then geocoded and reverse-geocoded to confirm. Owner declined a second pin for El Nido de Quetzalcóatl (the Parque Quetzalcóatl post also names this adjacent site) and the "Oficina Cueva" post (no publicly identifiable building — it's inside an unnamed Santa Fe, Mexico City tower). Dropped a proposed "Javier Senosiain" tag before merging — not in the app's `Tag.swift` architect vocabulary, and adding it is a code change outside this content PR's scope; the two Senosiain pins keep "Designed by a Master" only. `linkPins` 1,809 → 1,816, makers 385 → 386. `validate-tours-mirror.py` 0 errors (fixed 4 missing Theme/Place-type tags before merging). `check-image-duplicates.py --pins` clean. 8 files (7 heroes + 1 avatar) pushed to gh-pages in one commit (`695dc51`) via a plain `git push` from a worktree — `gh` CLI is unavailable in this session and the GitHub MCP file-write tools proved to mangle binary content (confirmed with a 256-byte round-trip probe before touching real images), hash-verified identical locally; CDN live-check still pending Pages deploy. |
| `claude/elegant-cerf-tsnbrz` | **MERGED as [#828](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/828), squash `0f73983`; branch auto-deleted** — 15 link pins from TikTok `@heyrosiedart` (London), triaged from a 30-link dump the owner pasted in unread. Triage read every oEmbed thumbnail, not just captions — Le Beaujolais, Michelin House, Wilton's Music Hall, Barbican Laundrette and Turquoise Island all named nothing in their captions and were identified from the video frame. `linkPins` 1,794 → 1,809, makers 384 → 385. Owner declined the Penguin Pool at London Zoo (otherwise a confident single-place ID) and left 4 multi-location roundups (swimming pools, ghost signs, music-video interiors) unminted pending a decision on whether to explode them. `validate-tours-mirror.py` 0/0 (fixed 5 missing Theme/Place-type tags before merging); 16 heroes+avatar hash-checked with no duplicates, pushed to gh-pages in one commit (`acb2170`) and hash-verified live on the CDN post-deploy. ✅ **Verified live:** `publish-catalog.yml`'s seed job applied cleanly (`catalog_snapshot_age()` rebuilt at `09:50:57Z`) and Supabase's `tours` table returns exactly 15 rows for `source_author=eq.@heyrosiedart`. No owner SQL owed. |
| `claude/amazing-rubin-pkub81` | **Open (the last three)** — **287 → 288 places**, and 🔴 **the sweep reaches 0 exact / 0 within 25 m open**. `The Gamble House` becomes a place; the `Noguchi Museum` tour and the loose `Habitat 67` pin join theirs. **Every one of these groups exists BECAUSE of a repair earlier today** — the entries always described one site, they simply were not standing on it. 🔴 **0 entries modified: nothing moved.** ⚠️ The Habitat 67 joiner is the pin that **made the place's own 363 m error visible** in the first place. ⚠️ The place is filed under **Pasadena** (where the building is) while its tour keeps its maker's `Los Angeles` — a deliberate split, since that maker files all 42 tours that way. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (three repairs)** — found by running the coordinate check across the remaining near pairs instead of ruling on them by distance. `Gamble House` **343 m** out, `The Noguchi Museum` **497 m** out, and 🔴 **`Habitat 67`'s PLACE 363 m out, carrying BOTH its members with it.** That last one is different in kind: a place's coordinate *is* its identity, so members are pinned to it and **cannot disagree** — the validator and the sweep were both satisfied, and only a **third pin outside the place**, 10.9 m from the real building, made it visible. **A place propagates a coordinate error; check the place against the source, not only its members against the place.** ⚠️ Each repair leaves an exactly-coincident group (3 now, from 0) — that is the truth, and those are place decisions deliberately not taken here. ⚠️ **Not changed, checked rather than assumed:** the Gamble House tour says `Los Angeles` where its pin says `Pasadena`, but that maker files **all 42** of its tours as Los Angeles — a convention, not a typo. Lesson in `docs/lessons.md`. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (the 26–49 m band)** — the owner's seventeen yeses: **271 → 286 places**, 15 new + 2 joins. 🔴 **The band exposes a systematic pattern: in FIFTEEN of the seventeen groups the LINK PIN sits on the OSM feature — usually to 0.0 m — and the Atlas TOUR is the entry that is off.** Pins are geocoded per link; a good number of these tours carry 4-dp coordinates typed once and never checked, the same signature behind all five of today's repairs. Every anchor is therefore *the member OSM agrees with*. ⚠️ **The Ansonia is the exception — BOTH members were off** (44 m and 74 m from OSM's building), so it is anchored on the one that keeps the other inside its own geofence. ⚠️ Also caught: taking OSM's **first** result was wrong for Port Authority (a subway station), Marmorkirken (a metro stop) and Villa Charlotte Bronte (a beauty salon **17 km away**) — the right feature was further down the list, and one group needed a re-query by street address. 11 of 18 moves are past their own radius, by **+1.2 m to +18.7 m**, all approved with distances shown. Sweep **0 exact / 38 tight / 30 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Z1–Z3 + the tight tier)** — **266 → 271 places**. 🔴 **The owner read the list and found a coordinate defect in it** — *"somehow a Lloyd's tour is closer to Leadenhall than to the other Lloyd's"*. Correct, and the **fifth defect of the day**: the `Lloyd's of London` TOUR sat at 4 dp **on The Leadenhall Building**, 92.8 m from Lloyd's. OSM settles it — its `Lloyd's of London` is the Lloyd's **pin** to 0.1 m, its `The Leadenhall Building` is the Cheesegrater **pin** to 0.0 m. ⚠️ **So P1 was never the false positive I called it.** I had recommended declining *Lloyd's / Cheesegrater at 7 m* as "two buildings across a street" — it was this defect in disguise, and declining it would have **buried the bug under a decision**. Repaired, they are 94.5 m apart and P1 stops existing on its own. Also: `Trellick Tower`, `Tate Modern`, and joins to `Walden 7` and `Leaning Tower of Niles`. Every move except the repair is **inside its own geofence — no waivers at all**. Sweep **0 exact / 38 tight / 50 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Z1–Z3)** — the owner's yes to all three exactly-coincident groups: **266 → 268 places**. `UIC Skyspace` (Chicago) and `Kubuswoningen (Cube Houses)` (Rotterdam) become places; the **Obama Presidential Center tour finally joins its own place** — the coordinate repair in #809 put it there and *BAND B ONLY* kept it out. 🔴 **Nothing moved: 0 entries modified**, which is what the exact tier means. ⚠️ Two guards fired and both were right: Z1's two pins share **the same title AND the same coordinate** (title+position is not identity either — they are separated by `sourceAuthor`), and a 6-dp anchor literal read as a **5.5 cm move** against the pin's real float, so the anchor is now taken **from the entry** rather than typed. ⚠️ `Cube House` already existed as a place — **Toronto's**, 6,000 km away and unrelated (Ben Kutner, 1996 vs Piet Blom, 1984) — hence the Dutch name. Sweep back to **0 exact** / 46 tight / 51 near. ⚠️ 3 validator warnings are **pre-existing** on the base (missing tags on pins from other batches), confirmed by running the validator against the stashed base. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (seed prune)** — 🔴 **`seed_from_toursjson.py` could never DELETE a place.** Caught by verifying #809 against the live database: the catalogue held **266** places and the live count read **267**, with **0 tours** pointing at the orphaned `Westerkerk` row that the Jordaan split had dissolved. An upsert-only seed can only ever grow. ⚠️ **Nothing downstream objects** — valid SQL, validator green (it reads only `Tours.json`), CI green, `get_catalog` serves it — the sole symptom is a count check that reads one too many, and that check is what the runbook uses to confirm a publish landed. The prune is emitted **after** the `place_id` reset because `tours.place_id` references `places`. Verified: the generated keep-list is exactly the 266 catalogue ids and Westerkerk is not in it. Lesson in `docs/lessons.md`. `backend/` + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Jordaan split)** — owner: *"split our Jordaan place"*. Both `The Jordaan` tours become their own place and 🔴 **the `Westerkerk` place DISSOLVES** — it only ever existed because the Jordaan **walk's introduction stop sits at the church**, so removing the walk leaves one entry describing Westerkerk, and one entry is not a place. The Westerkerk tour keeps its own coordinate. Anchored on **the walk's own stop 3, titled *The Jordaan***, which is exactly where the single-stop tour sat before Band C — so this **restores** that coordinate rather than inventing one (OSM's `place=quarter` centroid is 106 m away: agreement, not conflict for a neighbourhood). ⚠️ **The only walk move in the whole sweep** — its intro travels 136 m, and that is a fix as much as a cost: stop 0 currently sits on the **identical coordinate** as stop 1 *Westerkerk*, so introduction and first stop fire together. Owner also confirmed **Bosco Verticale is the towers** (already anchored there) and **Gamla stan's walk stays put** (already untouched). ⚠️ #810 merged under this branch — merged in; its 29 pins add fresh candidates, sweep now **1 exact / 43 tight / 51 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Band C)** — the owner's thirteen yeses from § 3's 100–200 m band: **8 new places + 3 joins, 258 → 266**, covering 643 entries. Same waiver discipline as Band B, at greater distance — the largest move is **194.5 m** (Stortorget into *Gamla stan*). 🔴 **Three more 4-dp coordinates found in the wrong place**: the `Neue Galerie` tour sat a full block east **on Madison rather than Fifth**, `Dennis Severs' House` **161 m** off Folgate Street, and the `Vasa Museum` tour **106 m** off the museum — each caught because the *other* member already sat exactly on the OSM feature. ⚠️ **`Bosco Verticale`'s pin sits on a RESTAURANT of that name, not the towers**, so the tour anchors it instead. ⚠️ **A walk may join only if it does not move** — `marker()` is the stop at order 0, so joining would relocate where a walk *begins*; *Gamla stan* is therefore anchored on its own 4-stop walk and **Stortorget travels instead**. ⚠️ Caught in flight: a 6-dp anchor read as a **2.8 cm move** against a full-precision float and tripped the multi-stop guard — identity is exact coordinate equality, so the test is now an exact compare, not a distance. Sweep **1 exact / 38 tight / 47 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Band B)** — the owner's eleven yeses from § 3's 51–99 m band: **8 new places + 3 joins, 250 → 258**, covering 624 entries. 🔴 **Every move here is larger than the entry's own trigger radius — that is what Band B is**, and each waiver is recorded against the entry it applies to (no radius was edited). Anchors chosen by evidence: five members' own coordinates already ARE the OSM feature (Oculus, Apthorp, Monadnock, Sagrada Família, Art Institute) so those anchor and do not move. 🔴 **A twelfth coordinate defect found:** the `Obama Presidential Center` **tour** sat **259 m** from every OSM feature of that name, at 4 dp — repaired to the museum, and **deliberately left out of the place** because the owner said *BAND B ONLY* and that pair is N60/N64. It now shows as the one open **exact** group, which is the sweep working. ⚠️ Also: `make-place-menu.py` gained `DECLINED_PAIRS` — § 3 had **no** way to hold a decision, so Tibidabo (declined in #541) and the owner's own Red Room and LACMA calls were being re-offered as fresh candidates. Sweep **1 exact / 38 tight / 57 near**. Content + docs + `scripts/` → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **MERGED as [#808](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/808), squash `751df7b`** — the **Academy Museum of Motion Pictures** becomes a place with *The Walt Disney Company Piazza*, **250 places**, and the coincident tier reaches **zero open groups**: 0 exact, 0 sites within 25 m. This candidate only existed because #807's coordinate repair moved the museum onto a pin whose own text reads "at the Academy Museum" — two independently sourced positions agreeing. **What remains is § 3's 75 same-subject pairs at 25–500 m**, never reviewed, where making a place means moving an entry hundreds of metres. ✅ **Verified live:** `get_catalog` serves **250 places** and `check-catalog-contract.py` returns **PASS** (snapshot rebuilt `12:09:53Z`). ⚠️ The `places` row count read **249 for 14 minutes after the merge** — the seed job is not instant, and a check run too early reads as a failure that is not one. |
| `claude/amazing-rubin-pkub81` | **Open (under-25 m batch)** — **26 more places, 222 → 248**, and the sweep reaches **0 exact / 43 tight / 77 near** with only **4 open groups left**. Includes a bespoke **Wall Street** place (the Atlas tour + *The 1920 Wall Street Bombing* + *The Wall of Wall Street*) whose two furthest members are 54 m apart, so it sits at their **midpoint** — no member's own coordinate could serve without pushing another outside its 30 m geofence. 🔴 **Two real coordinate defects fixed:** the `Marina City` TOUR sat **460 m west of Marina City, on top of the Merchandise Mart** (both were 4 dp), and the Madrid *Ring of Green* walk's intro stop sat 14 m from the Palacio Real at 4 dp — both re-sourced from OSM. 19 groups declined and recorded. ⚠️ **Caught mid-flight: the menu's `P` labels renumber when a batch lands**, so the declines were briefly recorded against the wrong groups; they are keyed by member titles now, and the lesson is in `docs/lessons.md`. **Then the last four coincident groups, decided:** *The Dark Secret of Wall Street* joins the Wall Street page (⚠️ **115 m — outside its 30 m geofence, waived on owner instruction**; its subject is Wall Street itself, so it reads as a correction), the Red Room stays separate, **Hell Gate Bridge becomes a place** (3 pins, all within 13 m), and the LACMA trio stay separate with their **pins repaired** — LACMA and the Academy Museum were both 4 dp and **151 m out**; they are now 175 m apart. 🔴 **That repair immediately exposed a new 0 m group**: the Academy Museum now sits exactly on *The Walt Disney Company Piazza*, a pin whose own text reads "at the Academy Museum" — independent corroboration the fix was right, and the one candidate left open. **249 places; sweep 0 exact / 39 tight / 75 near.** Content + docs + `scripts/` → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open as [#806](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/806)** — the place menu becomes a **generated** document (`scripts/make-place-menu.py`), and the owner's under-10 m batch lands: **41 new places, 181 → 222**, 85 entries, 43 of them snapped onto their site (every move inside its own 30 m radius, asserted). **Sweep 1/121/79 → 0/75/79.** Five groups declined and now recorded in § 4 so they are never re-offered — Stockholm's shopfront, *Britain's Oldest Door / Tomb of Elizabeth I* (both Westminster Abbey, already a place 17 m away), Barcelona's café/hotel, Madrid's *El Retiro / Puerta de Alcalá* (a 4-dp rounding artefact — **both those coordinates are imprecise**, worth fixing separately) and Hong Kong's two shops inside D2 Place. 🔴 Two real bugs found while building it: a literal `|` in a bilingual title **silently shifts every cell after it** in a markdown table (24 entries carry one), and addressing group members **by title picked the wrong entry in 11 groups** that hold two entries sharing a title. Content + docs + `scripts/` → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **MERGED as [#801](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/801), squash `e553227`; branch auto-deleted** — the place sweep. `check-place-candidates.py` gained a **TIGHT** tier (within 25 m whatever the titles say), because the title-containment rule is structurally blind to one site under two unrelated names — *Hook & Ladder 8* / *The Ghostbusters Firehouse* are 4 m apart and share no word; **82 of 151 TIGHT pairs were unreachable by any title rule**, 55 fully word-disjoint, and the old 148 NEAR pairs come back as 69+79 exactly. **Places 142 → 181**: § A 7 places / 8 entries, § B's 0 m rows 38 new places, and both held groups resolved by the owner (*Grand Central* pins joined the existing place at 88.4 m; *Tai Kwun* re-sited to the centre of OSM's 檢閱廣場 Parade Ground way, with *Madame Fu* relocated to its own published coordinate and **deliberately left outside** — a Tibidabo-style standing decision). 🔴 **"Adding the id is the whole change" was wrong**: identity is exact coordinate equality (1e-9°), so every joiner is **snapped**, each snap asserted inside its own `triggerRadiusMeters` — waived per entry, with a reason, only for the three owner-authorised moves that exceed it. **Sweep 41/151/79 → 0/117/78 and the checker now exits 0.** ⚠️ #802 landed between green CI and the merge; `mergeable_state` was re-checked as clean first. |
| `claude/tour-links-tstvw8` | **Open as [#789](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/789)** — 35 Instagram link pins from a random owner-collected batch (36 links, one dead); `linkPins` 1,644 → 1,679, `makers` 355 → 376 (21 new creators) — ⚠️ **rebased twice: `main` moved under this branch during its own CI**, so those are the second set of numbers, re-derived after resolving. 21 cities, 11 countries. 🔴 **No link came with a location**, so every coordinate was forward-geocoded and each returned name read back by hand — which caught four wrong subjects: the Huntington Beach **Central** Library (not the Banning branch), the **Runnymede Theatre at 2225 Bloor W** (not the library at 2178), **Aranya Wulingshan Phase 2** (which resolved only to its county until queried in Chinese), and **Conwell Cocktail Hall in New York's Financial District** — the name reads Philadelphian and is not. ⚠️ **The first geocode run reported "NO MATCH" for 30 of 35 subjects including Tribune Tower — that was HTTP 429, silently coerced into a negative result**, the § Reading a check's result trap in a fresh disguise; the script was rewritten to separate a failed fetch from a real miss. Five posts named no place at all and were identified from the video frame or research (111 Murray St · iMANISHi Sando Bar · St Vincent de Paul · On Labs Zurich · Conwell). Each pin minted with its own `--title` — a batch run takes the map title from the caption, which on Instagram is a paragraph. Validator 0/0 with self-test 32/32; 35 heroes, 35 unique hashes, all 1200×900, no filename collision against gh-pages' 7,514. **Two owner decisions in § 5.** Content-only → auto-merge class. |
| `claude/atlas-upload-link-pins-zb1l0o` | **Open as [#784](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/784)** — 27 link pins (Seattle, NYC, Stonehenge, Mont-Saint-Michel, Monaco, London, Pont du Gard, Chamonix, Lyon, Houston, Vence); `linkPins` 1,588 → 1,615. Coordinates OSM-verified and read back to the owner before minting. **11/12/13 share one TikTok post at three NYC monuments** — ids use the `#<city>-<title>` fragment scheme (docs/link-pin-runbook.md), one shared hero. **08/09 turned out to be two distinct Mont-Saint-Michel posts** (the abbey vs. a nearby basilica relic) that collided on hero filename twice — once with each other, once with a pre-existing `@urbanistariel` pin already live on gh-pages — both re-slugged rather than overwriting a live hero. Six free-text tags outside the closed vocabulary (`Ancient Monument`, `Abbey`, `Synagogue`, `Historic Market`, `Roman Aqueduct`, `Mountain`) mapped to valid equivalents; validator went 9 errors + 32 warnings → 0/0. Heroes live on gh-pages `e3950d4`, hashes verified; `check-image-duplicates.py --pins` clean (0 errors, 1,606 images). Content-only → auto-merge class. |
| `claude/inspiring-gauss-qwi8vu` | **Merged as [#782](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/782), squash `28409c0`** — 37 `@urbanistariel` link pins, `linkPins` 1,551 → 1,588. 🔴 **Katz's Deli arrived on a Plus Code that recovers to Albee Square, Downtown Brooklyn — 3.5 km away, wrong borough, and to the same point from a Manhattan reference too, so the code was wrong rather than its locality label.** Repinned at 205 East Houston Street; **owner confirmed the repin ("where you recommend")**. ✅ **The held-back Callanish link is DROPPED on owner instruction** — TikTok's oEmbed returned an empty author and no thumbnail on every retry while all 37 others returned both, so the post is gone; its Plus Code was good. Nothing from this batch is owed. ⚠️ `main` moved during CI (#781) and the merge conflicted on `archive/README.md` only — structural, both rows kept, `Tours.json` untouched by the merge. ⚠️ **Two pushes produced no `synchronize` event**, so CI was dispatched by hand twice — the exact gap `ci.yml`'s own `workflow_dispatch` comment documents. Heroes on gh-pages `5e15d8c`; mirror verified live carrying 1,588 pins. |
| `claude/tour-uploads-token-efficiency-hyrix3` (4th run) | **Open as [#764](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/764)** — closes the same-city link-pin id gap: when one post yields two pins in ONE city the city fragment collides, and **both times that happened the ids were invented on the spot** (Charging Bull, New York; Harry Potter, Edinburgh — #758, today). Rule is now `#<slug(city)>-<slug(title)>` on collision, and `merge-link-pins.py` **refuses an id it cannot derive**, naming the expected one. 🔴 **The five existing odd ids are NOT re-minted** — an id is identity; changing one makes phones lose the pin from saved libraries. ⚠️ A defect only the live catalogue exposed: grouping without dedupe made a re-merged pin count twice, breaking idempotence — all unit tests were green. 30/30 self-tests, catalogue untouched. |
| `claude/tour-uploads-token-efficiency-hyrix3` (3rd run) | **Open as [#759](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/759)** — the same append-forever pattern found in two more files: `archive/README.md` **474,582 → 31,588 B (−94%)** and `ROADMAP.md` **427,655 → 98,260 B (−77%)**, history moved verbatim to `archive/INDEX-DETAIL.md` and `archive/ROADMAP-STATUS-HISTORY.md`. **Zero lines lost on both**, verified against `git show HEAD:<file>`. 🔴 Turned up three defects: a parser silently dropping a third bullet format, a row mangled by a literal `|` inside a cell, and **`HANDOFF-260819.md` indexed but never committed** (row kept and marked, not deleted). ⚠️ Also fixed a stale "Active handoff" pointer and the wrong `ls … | tail -1` idiom (`-` sorts before `.`, so a `-2` suffix is discarded). **`STATUS.md` deliberately untouched** — prose about what the owner owes, no mechanical cut. Restarted from `origin/main` after #757 merged. |
| `claude/tour-uploads-token-efficiency-hyrix3` | **Open as [#757](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/757)** — `scripts/merge-link-pins.py` (merges a pin batch into `Tours.json` disk-to-disk, so its JSON never passes through a conversation — ~1.9 KB/pin measured, paid again on every later turn) + `docs/link-pin-runbook.md` (the uuid5 id scheme, verified live, with the command to re-prove it). Docs + `scripts/` only → auto-merge class. **Restarted from `origin/main` after #756 squash-merged and its branch was deleted — never stacked on merged history.** ⚠️ Found that `validate-tours-mirror.py` ALREADY carries the 32-case fault harness sessions kept rebuilding; no new one was written. |
| `claude/tour-uploads-token-efficiency-hyrix3` (first run) | **Merged as [#756](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/756), squash `f6adc5d`** — moved 34 dated Current State blocks out of `CLAUDE.md` into `archive/CURRENT-STATE-HISTORY.md` (1.5 MB → 47 KB, ~418k → ~13k tokens **on every request of every session**), added `docs/lessons.md`, and amended Automation Rule #5 + § Keep Docs in Sync so the narrative cannot grow back. Archive verified **byte-identical** to main's region. |
| `claude/tour-links-ds0387` | **Open as [#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734), all four checks green on `2b171cae`** — 33 Toronto + Mississauga link pins, **plus six places and two architects** on owner instruction, cut clean off `origin/main` `5763c137` and since merged with `main`. ⚠️ **A CODE change** (`Models/Tag.swift`), so it waits for owner OK + a simulator look. gh-pages `5308c563` carries its 33 heroes, **all hash-verified live against the uploaded bytes**. ⚠️ **gh-pages moved between the clone and the push** (`0b15aa4` → `a0cd018`, a parallel session's 17 heroes) — detected by re-reading `git ls-remote`, and the tree was **rebuilt on the current head rather than force-pushed**, with collisions re-checked against the new tree. |
| `claude/new-tour-links-cytwc6` | **Open as [#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729)** — 61 `@archimarathon` link pins plus two places, cut off `origin/main`. gh-pages `317046a` carries its 61 heroes. |
| `claude/tour-links-26dmsx` | **Merged ([#701](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/701), squash `5fc747fb`)** — twenty-eight Chicago link pins; linkPins 712 → 740, makers 247 → 262. ⚠️ **`main` moved THREE times while it was in flight** (#698, #699, #700 — 147 pins, the last arriving after the PR was open), and the catalogue edit was **redone each time by re-running the idempotent assembler on `main`'s file**, never hand-resolved. 🔴 **That caught a real hazard: #699 created maker rows for two of this batch's creators, so new rows went 17 → 15** — uuid5 reproduced both ids exactly; a naive resolve would have emitted `duplicate maker id` twice. ⚠️ **Handoff renumbered twice, to `-10`** — `-7`, `-8` and `-9` were all claimed by parallel sessions on the same afternoon. Story in `CLAUDE.md` § Current State |
| `claude/tour-links-upload-tbcerj` | **This session, pushed, no PR** — twenty link pins (15 × `@breatheart_hk` Hong Kong). Cut off `origin/main` `05e90f47`, **rebased onto `00a420bd`** after #640 and three doc commits landed mid-session; catalogue edit redone by re-running the idempotent assembler against the new `main`, never hand-resolved. gh-pages `a8a81767` |
| `claude/tour-links-upload-wa3e0g` | Merged (#640, squash `cd32e293`) — 32 pins. ⚠️ **Its branch diff was 33 pins, not 32**: it carried the Instagram Zacherlhaus the owner pulled in #641. Flagged pre-merge; **checked after and the pull held** — only the TikTok Zacherlhaus is on `main` |
| `claude/tour-links-upload-qeoxe7` | **Merged as [#648](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/648); follow-up places PR open** — twenty-three link pins from three creators (18 TikToks `@thedesigndetourist`, 4 Instagram `@shaunbirley`, 1 `@meliluu__`); linkPins 168 → 191, makers 154 → 157. Content only, images live on gh-pages at `251cf95e`. **🔴 MERGE HAZARD, NOW THE OTHER SESSION'S: this branch created the `TikTok @thedesigndetourist` maker row (uuid5 `67CA14A6-…`) and a parallel session's unmerged branch creates the identical id — that branch must drop the duplicate or the validator errors.** ⚠️ Ships two subjects twice on one coordinate each (Westin Bonaventure, Hotel Casa del Mar) — deliberate, both links were sent; `check-place-candidates.py` therefore reports 3 EXACT groups against main's 1 |
| `claude/project-tracking-dashboard-1kggmu` | **This session — restarted from `origin/main` `5e75112`, never stacked on merged history.** Its previous commit (`eee22bb`, one paragraph added to `release_notes.txt`) was **deliberately dropped, not landed**: 1.1.1 has since shipped, so that file is now the *published* notes and the next edit to it is a rewrite for 1.1.2 — see § 1d and `docs/launch-runbook.md` § Shipping an update, which this branch corrects instead. |
| `claude/link-fullscreen-probe` | 🔴 **Never merged, still on the remote** — carried the temporary readout and builds 131/132/133. **Owner deletes it in the GitHub UI**; the git proxy blocks branch deletion from a session |
| `claude/link-fullscreen-window` | Merged (#622, squash `e22dba7`) — the real fullscreen fix |
| `claude/link-fullscreen-module-ojs556` | Merged (#617, squash `adbe3b94`) — the `onDisappear` guard. ⚠️ The designated branch name; the first attempt's work was actually on `claude/link-fullscreen-module` |
| `claude/link-fullscreen-module` | Merged (#611, squash `8df37de8`) |
| `claude/new-tour-links-nniny1` | Merged (#626, squash `303012b3`) — nineteen San Francisco architecture link pins. **Verified live on BOTH sources afterwards**, not on the merge: the RPC and the gh-pages mirror each serve 76 link pins with 0 wrongly inside `tours`, and `places` / `priceTier` / `isPrivate` all survived. ⚠️ Restarted from `origin/main` for this board update — never stacked on merged history |
| `claude/new-tour-links-yr5o7r` | **Open as [#627](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/627)** — ten "Atlanta Architecture" TikToks, **nine shipped as link pins; the tenth (Mercedes-Benz Stadium) pulled by the owner over a probably-AI hero**. Cut clean off `origin/main` `c5e8862`, then **merged `main` in to resolve a four-way conflict with #626** (both batches touched `Tours.json`, `CLAUDE.md`, `STATUS.md`, and both claimed `archive/HANDOFF-260827.md`). Content only. Images live on gh-pages at `a93c06d4`. |
| `claude/tiktok-orlando-links-ziegoe` | **Restarted from `origin/main` after #621 merged** — now carries the Orlando *architecture* batch (10 pins, commit `da9c96ad`). ⚠️ Same branch name, fresh history: never stacked on merged commits. |
| ~~`claude/tiktok-orlando-links-ziegoe` (first run)~~ | Merged as #621 (squash `1c05613b`) — nine Orlando link pins, live on Supabase |
| `claude/library-launch-jitter` | Merged (#549 at 03:52) — auto-delete should remove it |
| `claude/upload-wizard-improvements-ejopz3` | Merged (#552 at 19:05) |
| `claude/wizard-comments-round2` | Merged (#558) and deleted |
| `claude/launch-performance-animations-df4d7p` | Merged (#559 at 16:43) — built as 108/109 |
| `claude/milan-tours-upload` · `claude/milan-docs-260822` | Merged (#560, #561) |
| `claude/coordinate-guard` | Merged (#562 at 17:20) |
| link-pin branches (#584, #585, #586, #587) | All merged 20:59–22:51; auto-delete should remove them |
| `claude/link-pin-batch-workflow` | Merged (#588 at ~01:40) |
| link-pin follow-ups (#589–#595) | All merged 01:40–03:10 |
| `claude/ellipsis-button-consistency-vdorpi` | Merged twice from one branch (#553, #555). ⚠️ The second stacked on already-merged history, which CLAUDE.md says to avoid — it worked, but no PR existed while build 95 was installable |
| `claude/tour-upload-polish-qiliop` | Merged (#540) — auto-delete should remove it |
| `claude/stripe-questions-fjhdo3` | ⚠️ No PR — verify contents before deleting |
| `claude/amsterdam-handoff-preserve-hlhyp8` | 🔒 Keep — only copy of staging pick-maps |
| `claude/web-landing-site-preserve` | 🔒 Keep — only copy of the Next.js landing site |
| `claude/london-batch3-scripts-260616` · `claude/paris-scripts-260622` · `claude/dreamy-wozniak-tags-260612` | 🔒 Keep (documented archival) |


### § 1 — awaiting owner, as it stood

## 1. Awaiting owner — device review

🟡 **OPEN — [#820](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/820) — Search maker "N tours" counts going stale while the screen is already open (2026-09-11).** Found right after #815 (the 17-link-pin batch) merged: the owner searched for a just-added creator and saw "0 tours"; an existing creator was stuck at its pre-batch count. Live `get_catalog()` checked directly first — data was correct — so this is `SearchView`'s own maker-count cache never refreshing except on the screen's next `.onAppear`. One-line-ish fix: `.onChange(of: dataService.tours.count)` added alongside it. No functional risk to the cap/ranking logic `SearchResultsTests.swift` covers, but it is `Features/**/*.swift`, so per policy it waits for a device check: open Search, match a creator, and confirm the count looks right (ideally right after a fresh catalog fetch/relaunch, since that's the case that was silently wrong).
  - ⚠️ **Conflict resolved 2026-09-12 by the coordinator session, NOT by this PR's author.** `main` moved 23 commits under it and the ONLY conflict was this file — `SearchView.swift` has not been touched on `main` since the branch forked, and its bytes are asserted identical to the author's. `main` was merged in rather than rebased, so the author's checkout stays valid.
  - ⚠️ **Known limitation, pre-existing and carried forward rather than introduced:** the guard fires on `dataService.tours.count`, so a refresh that EDITS a tour without changing the count still leaves the index stale. That is `buildIndexIfNeeded()`'s own size-guard, not this PR's doing — worth knowing before signing it off as "counts are now always right".

🆕 **OPEN — [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776) — the catalogue version check: ask 34 bytes before downloading 3.4 MB (session 153, 2026-09-09).** ✅ **CI GREEN on the code commit — all three jobs, `** TEST SUCCEEDED **` read from the job log, not from a badge.** 📲 **SUPERSEDED — build 142 is STALE; TestFlight build (144) DISPATCHED 2026-09-11 00:27 UTC from `e8343cae`** (run [34546576140](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/actions/runs/34546576140)), cut after merging 24 commits of `main` in. ⚠️ **Build numbers are a counter shared across ALL branches, so a HIGHER number does not mean it contains this PR** — build 143 came from another session's branch (#785) and carries none of this. The owner had installed 143 and would have been testing the wrong thing. Superseded: build (142) dispatched 2026-09-09 11:44 UTC from `ab841f7c` — run [34347144761](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/actions/runs/34347144761), build number re-derived from the Actions run list (`BUILD_NUMBER: github.run_number`), with plain-English notes attached to the build's *What to Test*. **Owner is checking it on device before merge.** 🔴 **CODE — `Data/RemoteCatalogLoader.swift` + `SupabaseConfig.swift`, so it needs explicit owner OK and a device check.** Option A from `docs/catalog-version-check-design.md`, which the owner chose after reading it. Before fetching from Supabase the loader calls `catalog_snapshot_age()` (**34 bytes, ≈0.3 s**, both measured live) and skips the **3.4 MB** download when that token matches the one stored beside a still-readable cache.
  - ✅ **No SQL, nothing for the owner to paste** — `catalog_snapshot_age()` already exists and is already granted to `anon`.
  - **Why it is safe:** `payload` and `refreshed_at` are two columns of the *same* row in `catalog_snapshot`, written by one upsert, so the token cannot disagree with the catalogue it describes. The silent-staleness failure (2026-08-19's shape) is structurally unreachable; the only error direction is a harmless extra download. Everything **fails toward downloading** — a probe that errors, times out, or answers oddly changes nothing.
  - ⚠️ **Two bugs the design doc missed, found while building and fixed here:** (1) "up to date" must **stop the source chain** — falling through would have downloaded the whole gh-pages mirror to learn what we already knew, saving exactly zero; (2) a cache written from the mirror must **clear** the stored token, or a later probe would match it and pin the app to the mirror's copy.
  - **8 new tests** (26 total in `RemoteCatalogLoaderTests`), incl. matching-version-but-corrupt-cache, failed-download-does-not-advance-the-token, and mirror-path-unchanged.
  - **What it does NOT fix:** when anything changes the app still downloads all 1,552 tours. Next and larger: dropping `transcriptText` (38% of payload) + `longDescription` (18%) — deferred, it is a breaking catalogue change.

🆕 **OPEN — [#769](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/769) — Trinity Church, Madison Square Garden and Penn Station become places (session 152, 2026-09-09).** Owner instruction, Penn Station added on a follow-up ask. **places 137 → 140**, `tours`/`linkPins`/`makers` otherwise byte-identical; diff **48 insertions / 16 deletions**, the deletions being the four member coordinates moved onto their place point. Content only — auto-merge class.
  - **Trinity Church (3):** the Atlas Studio NYC tour plus `The Details Inside Trinity Church` and `Trinity Church, Older Than the United States`, which sat 26 m away **on one identical coordinate**.
  - **Madison Square Garden (3):** the Atlas tour plus the `@hereinnyc` Knicks and Rangers pins, 19–20 m away.
  - 🔴 **MSG's anchor is GEOFENCED**, so the place took *its* coordinate and only the two link pins moved. Both movers assert `kind == "link"` and `triggerMode == "manual"` before touching anything, and every anchor is asserted unmoved afterwards.
  - **Penn Station (4):** `The Hidden Message in Penn Station`, `Signs of Penn Station's Glorious Past`, `A Penn Station Eagle`, `The Old Penn Station Mosaics` — kept out of MSG deliberately (same structure, different subject), then made their own place when the owner asked. **No Atlas tour here, so it is anchorless** — 57 of the live places already are — and the coordinate is OSM's own `New York Penn Station` node, which two of the four pins already sat on exactly. ⚠️ **The Eagle moves 157 m and the Mosaics 136 m**; the other two move 0. `The Red Room at One Wall Street` and `The Buttonwood Tree at the NYSE` likewise stay out of Trinity Church.
  - ⚠️ **`Penn Station's Lamppost at St. John the Divine` is NOT a member** though its title says Penn Station — the lamppost was moved to the cathedral and the pin belongs to that place, 6 km away.
  - 🔴 **NEITHER GROUP WAS ACTUALLY OVER THE MAP'S CAP, and the earlier claim that they were was wrong** — it came from a 65 m proximity sweep, which is a *candidate finder*, not the cap. The stack only forms for markers sharing a cluster cell (~3 m at building scale). **Catalogue-wide, exactly 0 loose groups are coincident at or over the cap.** These two places are a curation decision, not a defect fix.
  - ✅ Place ids from `uuid5(NAMESPACE_URL, "atlas-place:<slug(city)>:<slug(name)>")`, **the scheme re-proved against 12 live places before minting**. Addresses from OSM; heroes are existing gallery images confirmed **HTTP 200**. Mirror **selftest 32/32, control clean, 0 errors / 0 warnings** across 1,552 tours + 1,489 pins + 140 places.




🔴 **OPEN — [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776) — ask 34 bytes before downloading 3.4 MB. WAITING ON YOU SINCE 9 SEP; NO LONGER CONFLICTED.**
  - **What it does:** before pulling the catalogue, the app asks `catalog_snapshot_age()` — **34 bytes** — and skips the download when nothing has changed. It is the *frequency* half of the egress fix; [#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795), now merged and live, was the *size* half.
  - ⚠️ **It was conflicted for two days and a conflicted PR shows NO checks here, so it looked pending rather than blocked.** Re-tested 2026-09-12: **merges cleanly**, 35 commits behind `main`. Nothing is stopping it but a review.
  - **No SQL to paste** — `catalog_snapshot_age()` already exists and is already granted to `anon`.
  - **The device check is two minutes:** open the app, close it, reopen it with nothing changed → content still correct. Then after a content merge, reopen → the new content arrives.
  - ⚠️ Touches `Data/*.swift`, the launch path, so it is code-class: **explicit OK plus that device check**. When this kind of code goes wrong the symptom is not a crash but an app showing old content or nothing.

🔴 **This section is for what is STILL waiting on the owner. It is not a log.**
41 finished items — every one whose pull requests GitHub reports as
merged or closed — moved verbatim to
[`archive/STATUS-HISTORY.md`](archive/STATUS-HISTORY.md) on 2026-09-08. Nothing
was deleted.

They had grown § 1 to **147,843 of this file's 205,618 bytes (72%)**, which is
precisely what this file's own header forbids: *"when an item here is finished,
it leaves this file… never let this file grow a history section."*

⚠️ **Four of them were still labelled `OPEN` while GitHub had them merged**
(#762, #748, #715, #691), as was Riverside Church, whose branch is gone and
whose place is in the catalogue. A label is not a state. **Re-derive before
trusting any line here:**

```bash
gh pr list --state open      # or the API; this board goes stale on every merge
```

✅ **CLEARED — the last `@urbanistariel` link is placed (2026-09-09).** The owner was asked where
`7255575696582446378` ("buildings that look like the Parthenon — they're everywhere") should go and
answered: **the Parthenon itself.** It ships as **The Parthenon: Copied Everywhere**, on the exact
coordinate of the existing `The Parthenon` pin, so the two form a **2-card coincident stack against
`TourSetMap.maxStacked = 3`** — one marker, headroom kept. **linkPins 1,550 → 1,551.** All 62 of the
batch's links are now live; nothing from it is owed.
  - ✅ **RESOLVED — the owner asked for a place, so `The Parthenon` is one** (places 140 → 141,
    `atlas-place:athens:the-parthenon`). All three pins are its members and collapse to a single
    marker. **Making it required moving `The Parthenon: The Missing Roof` 9.7 m onto the place
    coordinate** — `validate-tours.swift` hard-errors on a member whose `stops[0]` is off it, so a
    place cannot merely gather nearby pins. The Erechtheion (89 m) and the Theatre of Dionysus
    (147 m) keep their own pins, correctly.

🔴 **[#762](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/762) IS MERGED — kept here ONLY for its unresolved [#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) follow-ups below (a third Tower Bridge entry, a hero-filename collision). This item said `OPEN` for a day after it merged.**

Originally read:

> 🟡 **OPEN — [#762](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/762) — twenty-seven `@urbanistariel` link pins (session 150, 2026-09-08).** The owner sent 28 TikTok links; **27 ship, 1 is refused** because TikTok returns a completely empty oEmbed record for it (no author, no title, no thumbnail), so there is no hero to crop. **linkPins 1,426 → 1,453 · `tours`, `makers` and `places` otherwise byte-identical.** Content only — **auto-merge class**, squash on green CI.
 — twenty-seven `@urbanistariel` link pins (session 150, 2026-09-08).** The owner sent 28 TikTok links; **27 ship, 1 is refused** because TikTok returns a completely empty oEmbed record for it (no author, no title, no thumbnail), so there is no hero to crop. **linkPins 1,426 → 1,453 · `tours`, `makers` and `places` otherwise byte-identical.** Content only — **auto-merge class**, squash on green CI.
  - 🔴 **Three Met pins would have been a 4-deep stack at one coordinate** against `TourSetMap.maxStacked = 3`, one silently unreachable. Folded into the existing **Met place** instead (2 → 5 members), so they collapse to one marker. Catalogue-wide, **no group exceeds the cap** once place members are excluded.
  - 🔴 **Two coordinate defects caught that no downstream check would have.** A naive short Plus Code recovery put `P272+V9 New York` at longitude **−74.999** (rural Pennsylvania) — fixed with the real OLC `recoverNearest`; and `Park Avenue Plaza, New York` geocoded to **a village near Corning, 250 km upstate**, a real place that reverse-verification would have confirmed. **A bounding box per caption-named city is what caught it: 27/27 in box.**
  - ⚠️ **A hero filename would have overwritten a live file belonging to the then-unmerged 83-pin batch** (same creator, different post about Mount Prospect Park). Renamed; that batch has since merged as **#758**, and this branch was rebuilt on it — main's `Tours.json` taken wholesale and the idempotent assembler re-run.
  - ⚠️ **Flagged, not fixed:** `The Met's Design Flaw` sits 17 m off the Met place and is not a member, so it remains a lone pin beside it. Pre-existing on `main`; one line, owner's call.
  - ✅ **Five more places on owner instruction, closing every at-cap group in the catalogue (places 132 → 137):** Eldridge Street Synagogue · ParkLife · Awaji Yumebutai · Equilateral House · M+ Museum. 🔴 **The owner corrected the report while asking** — *"M+ HAS 4 TOURS"* — and was right: the sweep grouped by **exact coordinate**, so Atlas Studio HKG's `M+ Museum | M+博物館` at **54.3 m** was invisible to it. **An at-cap check keyed on exact equality understates any group with an Atlas tour nearby.** ⚠️ **Eldridge Street's anchor is geofenced** and already sat on the pins' point, so nothing moved there; only M+'s three link pins moved, onto their anchor tour. **Deepest loose group catalogue-wide is now 2.**
  - 🔴 **[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) is still OPEN** — the owner asked whether its 54 pins had been sent; they had, and are still unmerged. **Verified link by link** (every `vm.tiktok.com` short link resolved through its redirect first), 49/49 present. One coordinate disagreement noted there: the `QHVR+HQ Nob Hill` code re-sent for San Francisco *Chinatown* is **153.6 m** from the live pin, which kept its August coordinate.
🆕 **OPEN — `claude/new-tour-links-zaguqm` — two places on owner instruction: United Nations Headquarters (6 members) and Tower Bridge (2) (session 149, 2026-09-08).** Owner asked for both after #758 merged; the owner's own count of "6 tours" at the UN was **correct and re-derived** — 5 new `@urbanistariel` pins plus the existing Atlas Studio NYC `United Nations Headquarters` tour. **places 130 → 132.** Content only. Diff **58 insertions / 24 deletions** — the deletions are the six member coordinates being moved onto their place point, which `validate-tours.swift` requires exactly.
  - 🔴 **THE GEOFENCED TOUR DID NOT MOVE.** Atlas Studio LDN's `Tower Bridge` is **`geofenced`**, so the place was put on **its** coordinate and the link pin moved onto it — the pin moves, never the tour. The UN anchor is `manual` and also left where it was. Asserted after the edit: both anchors unmoved, and the only six entries whose coordinate changed are the pins. The mover **refuses a non-`manual` stop** rather than trusting the author.
  - ⚠️ **The UN place supersedes #758's four-feature spread.** That spread existed only to dodge `maxStacked = 3`; a place collapses them into one marker, so all six now sit on one point as the validator requires.
  - 🔴 **[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) CARRIES A THIRD TOWER BRIDGE ENTRY AND IT IS NOT IN THIS PLACE.** It could not be — `tourIds` must reference a tour already in the catalogue. **Whoever merges #749 must add its `Tower Bridge` pin to the `Tower Bridge` place AND move it onto `51.5055,-0.0754`**, or it draws a second marker beside the place. That also resolves the duplicate-title finding, since #749's pin is titled `Tower Bridge` exactly like the Atlas tour.
  - ✅ Mirror **selftest 32/32, control clean**, then **0 errors / 0 warnings across 1,552 tours + 1,426 pins + 132 places**, exit read directly. Place ids `uuid5(NAMESPACE_URL, "atlas-place:<slug(city)>:<slug(name)>")`, **the scheme asserted against a live place before minting**. Both place heroes re-use existing gallery images confirmed **HTTP 200**; addresses taken from OSM reverse geocodes, not recall.


🆕 **OPEN — [PR pending] `claude/new-tour-links-zaguqm` — eighty-three link pins from TikTok `@urbanistariel` (session 149, 2026-09-08).** 83 short links → **82 distinct posts → 83 pins**, because one Harry Potter post carries two Edinburgh Plus Codes (The Elephant House + George Heriot's School) and ships under the documented shared-post fragment scheme with **one shared hero — so 82 hero files cover 83 pins**. **linkPins 1,343 → 1,426 · `tours`, `makers` and `places` byte-identical** (the `@urbanistariel` maker row already existed and is byte-identical, so makers stay at 353). Content only — the auto-merge class. **Malta and Croatia are the catalogue's 60th and 61st countries.**
  - 🔴 **A HERO FILENAME COLLIDED WITH THE UNMERGED [#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) AND WOULD HAVE OVERWRITTEN A LIVE FILE.** Both batches carry a different `@urbanistariel` post about **Tower Bridge**, and the handle suffix cannot disambiguate one creator posting twice about one venue. Mine was renamed to `tower-bridge-glass-walkway-urbanistariel_hero.webp`; #749's live bytes were never touched. **A batch running beside another must diff its hero filenames against the gh-pages tree, not just against `main`.**
  - 🔴 **MOCA WOULD HAVE SHIPPED A PIN NOBODY COULD TAP.** Three of these posts are the Museum of Chinese in America and `main` already carries one, giving **depth 4 against `TourSetMap.maxStacked = 3`** — `prefix(3)` silently drops the rest. `Two Centuries of NYC's Chinatown` moved **405 m** onto OSM's Chinatown neighbourhood node, which is what its caption is actually about. **Nothing is over the cap; seven clusters sit exactly at 3.**
  - ⚠️ **THE FIVE UNITED NATIONS POSTS ARE SPREAD ACROSS FOUR REAL OSM FEATURES** (Headquarters ×3, Secretariat, complex centroid) so all five stay reachable. The spread keeps them tappable; it is **not** a claim about interior precision. **Owner may prefer a place instead.**
  - ⚠️ **ONE COORDINATE DOES NOT MATCH ITS CAPTION AND SHIPS AS SUPPLIED.** `J4X6+X6` puts the Black Death / first-quarantine post on the **Homeland War Museum on Mount Srđ, ~950 m above Dubrovnik's Old Town**. Kept as the owner supplied it, flagged rather than moved — the Seronera precedent.
  - ⚠️ **`Tower Bridge` is titled identically on `main` (an Atlas Studio LDN tour) and in #749 (a link pin), on one point.** Not this batch's to fix — mine reads `Up Inside Tower Bridge` — but it is the Railway Museum duplicate-title shape and #749's to resolve.
  - ✅ Mirror **selftest 32/32, control clean**, then **0 errors / 0 warnings across 1,552 tours + 1,426 pins + 130 places**, exit code read directly. `make-link-pin.py --selftest` **71/71 with Pillow installed first** (a bare container reports 62/62, which reads as a pass and is not one). gh-pages `d232ae3a`: remote head re-read in the same command as the push, status via `PIPESTATUS`, diff **exactly 82 additions / 0 modifications / nothing outside `images/`**, and **all 82 blobs confirmed byte-identical in the pushed tree**.


🔴 **Do NOT wire them on "the links work on my phone" alone.** The owner is signed in; the app's
`WKWebView` is not. With a null context the app's embed — `instagram.com/reel/{code}/embed`, the same
URL — renders **blank**, and there is no `display_url` so **no hero exists either**. A forced pin looks
right to the owner and is a dead card for every other user. **Verify the field, not the phone.**

**⚠️ It is an ACCOUNT-level block, so one post answers for all six**: 25 posts from 21 other creators
carried a full context in the same runs; all 6 from this one creator carried none.

**If the subjects matter sooner:** the owner rates these as quality tours, and an Atlas tour beats a link
pin anyway — it works offline, downloads, and fires at a geofence, none of which a link pin can do.
⚠️ Toronto already has **42** Atlas tours, so check for overlap before drafting.


🟡 **(superseded, kept for the decisions)**
Owner sent 31 Instagram reels as "Toronto links 260901". **linkPins 565 → 590 · makers 226 → 246**;
tours and places unchanged. **Toronto's first pin batch** — 42 Atlas tours, zero pins before.
Committed `f62daa8c` and pushed; gh-pages `a506a5b` with all 25 heroes hash-verified live.
**PR #698 opened on owner instruction — CI is the authoritative validator and nothing compiled locally.**
🔴 **Links 1, 2, 4, 8, 9, 10 are ALIVE, not dead — the owner opened them on their phone, correcting an
over-read on my part.** The real cause is `contextJSON: null` on the embed page: Instagram withholds the
media context from a logged-out reader. **They still cannot ship** — the app builds that same embed URL
and is logged out, so a pin would render blank and has no hero either. **NOT WIRED**; nothing was
removed. ⚠️ **Owner can settle WHY by sending the creator handles** — a private account says so publicly.
**Three things remain the owner's call:** (1) the **Cube House pair** ships as two pins, which takes
`check-place-candidates.py` **0 EXACT → 1** — honest, neither pin nudged, one line removes either;
(3) **three weak heroes**, **One King West** sharpest (its frame is the CN Tower, not the vault);
(4) **four place candidates** — ROM 9 m, Casa Loma 11 m, Distillery District 40 m, Osgoode Hall 57 m.
⚠️ **`Diminish and Ascend` is pinned at Christchurch though its thumbnail shows Waiheke — owner
decided: *"keep christchurch."* Settled; do not "fix" it.**


🔴 **OPEN, NEEDS AN OWNER DECISION — `MoMA PS1` SHIPS A DEAD HERO IMAGE.** Its
`heroImageURL` returns a hard **404**, confirmed across seven spaced attempts against four
same-host controls that all return 200, so it is not the rate limiting that hid it. **The tour has
no gallery**, so there is nothing to promote in its place (the Castello / DuSable free fix does not
apply) — a replacement has to be sourced through the image pipeline, which means owner picks.
**⚠️ It is the ONLY `upload.wikimedia.org/wikipedia/en/` URL in the catalogue** — an English
Wikipedia *local* upload rather than a Commons file, which is where non-free/fair-use images live
and where deletion is routine. Everything else Wikimedia-hosted is on Commons and healthy. **One
dead image in 5,848**, found only because #659's fetch fix stopped error-page bodies being hashed
as though they were pictures.


### § 2 — blocked on owner, as it stood

## 2. Blocked on owner — outside the repo

**🔴 STANDING OWNER DECISION — NEVER DELETE A USER ACCOUNT. "0 tours doesn't mean anything."**
Stated 2026-09-12, and it restates the decision of **2026-08-25** already recorded in
`backend/remove_test_creators.sql` (*"clear the test creators, keep the real accounts"*). Every
`makers` row carrying a `user_id` is a person with an account. A maker row is created for **every
signup** by `handle_new_user()` in `backend/accounts.sql` — consumer or maker alike — so **"no tours"
carries no information about intent**, and the apparent count is read through a published-only view
that hides `taken_down` and draft rows anyway. **No session may delete, merge or "tidy up" accounts.**
Presentation is the only lever: decide what a creator search should list.

**🟡 OWNER REQUIREMENT, 2026-09-12 — every user needs a unique username. NOT YET DESIGNED.**
There is **no username/handle column at all** today: `display_name` is the only name, it has **no
unique constraint**, and `ProfileEditorView` lets anyone set it to anything with no availability
check. 416 makers, 401 distinct names, one collision (`New Creator` ×16 — the no-name-supplied
fallback).
  - ✅ **Additive, not a migration:** nothing in the app resolves a maker by name — every reference
    goes through the UUID.
  - **Recommended shape: a new `handle` (unique) BESIDE `display_name` (free text, duplicates fine)**,
    as Instagram/TikTok/GitHub do. Making `display_name` itself unique is the wrong fix — it would
    tell the second real person of the same name that they cannot use it.
  - 🔴 **The open question is the namespace.** The 319 pinned creators already carry handles, but
    inside the display-name string (`TikTok @pacificmodernism`); their uniqueness is enforced only
    structurally, by `uuid5(platform + lowercased handle)` in `make-link-pin.py`. The same handle on
    two platforms is legitimately two rows — `@pacificmodernism` was exactly that until today.
    Proposal: a real `platform` column, unique on **`(platform, handle)`**, Atlas accounts on
    `dozent`. That also ends parsing the platform out of a name prefix.
  - ⚠️ **Impersonation is the reason not to defer it:** nothing today stops a signup setting its
    display name to `Instagram @urbanistariel`, byte-identical to a real pinned creator in the
    catalogue.
  - **Next step: a design doc for the owner to choose from** (the pattern of
    `docs/catalog-version-check-design.md` and `docs/filter-chips-design.md`) covering the namespace,
    handle rules, backfill for the 16 unnamed rows, and whether pinned handles are reserved. **Not
    written yet.**

**✅ CLEARED 2026-09-12, 21:17 UTC — the owner pasted the SQL and the duplicates are gone.**
**Verified after the paste, four ways:** the row count went **3,441 → 3,439** (exactly two fewer),
both pin ids return empty, the orphaned `Instagram @pacificmodernism` maker row is gone — so the
conditional delete fired, confirming it held no other pins — and **`catalog_snapshot_age()` reads
`2026-09-12T21:17:56Z`**, which is the part that matters: the RPC serves a materialised snapshot, so
the paste only reaches a phone because that last line rebuilt it. ✅ **Both TikTok replacements
survive** (`145 Natoma`, `The Wind Harp`, one each on maker `537cc385`), which is the check worth
doing after any deletion — the risk is removing the survivor, not the duplicate.

**What it was.** Found the same day by diffing the live `tours` table against `Resources/Tours.json`:
the database held **3,441 rows against the catalogue's 3,438**, and every catalogue entry was
present, so nothing was *missing* — three rows were *extra*. Two of them are the `@pacificmodernism` **Instagram** pins that
[#804](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/804) replaced with TikTok equivalents:
**145 Natoma Street** and **The Wind Harp**, both San Francisco. `seed_from_toursjson.py` is
**upsert-only**, so deleting them from `Tours.json` reached the gh-pages mirror and the bundled seed
and **never reached Postgres — the app's primary source.** The snapshot is rebuilt from that table,
so the map is serving the old pin and the new one on the same spot.

  - **The fix was `backend/remove_pacificmodernism_instagram_duplicates.sql`**, written by
    [#805](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/805) for exactly this. It named the two
    ids explicitly and ended with `select public.refresh_catalog_snapshot();` — **that last line was
    load-bearing**, and the snapshot timestamp above is the proof it ran.
  - ✅ **The third extra row is NOT a defect and must not be deleted.** `Pigalle Duperré Basketball`
    (Paris) belongs to maker **"Wes the Wanderer"**, has a real `user_id`, a Supabase Storage hero and
    `is_private = true` — an **in-app maker upload**, which lives only in Postgres by design. A
    catalogue-vs-database diff will always show maker uploads as extra; that is correct behaviour.
  - 🔴 **The durable gap was the process, not the SQL, and it outlives this item.** #805 merged on
    10 Sep carrying an owner action, and no session put it in § 2 — so it sat owed to nobody for two
    days while the defect it fixes was live on the map. **A merged PR that needs an owner paste is not
    finished; it moves here.** The paste itself took the owner under a minute once it was asked for.
  - ⚠️ **This is only findable by diffing the database against the catalogue** — `validate-tours.swift`
    passes, CI compiles, every URL 200s, and the app shows two pins where one belongs. The diff recipe,
    with the two traps that make it lie, is in `CLAUDE.md` § Egress. **Worth running after any content
    removal.**

**🔴 THE SUPABASE OVER-QUOTA EMAIL WAS OUR OWN TOOLING, AND THE LINE ITEM WAS MINE.** The owner was
emailed on **2026-09-08** for exceeding the free egress quota. The largest single cause was a check
**I added to `scripts/session-start.sh` the same day** ([#761](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/761)):
it called `get_catalog` **four times per session** to read a status code and threw every byte to
`/dev/null` — **~44 MB of egress at the start of every session**, on a script Automation Rule #1
makes every session run. I never measured the payload I was pulling. ✅ **Fixed by another session in
[#770](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/770)**: `--compressed --max-filesize 2000`
takes the same check to **8 KB**, with the timeout detection proved intact rather than assumed. The
standing rule and the cheap alternatives are now in **`CLAUDE.md` § Egress** — read it before adding
anything that touches the RPC.

⚠️ **I nearly repeated it the next morning**, firing a 20-call uncompressed sample (~220 MB) before
recalling the incident; it was killed a few calls in, so **some tens of MB were still spent.** The
durable lesson is narrower than "be careful": **a probe that discards the response still pays for
it, and `-o /dev/null` hides that from you.** ⚠️ **And the quota is not fixed, only postponed** —
#770's own arithmetic puts a daily active user at **~240 MB/month**, so roughly **20 users** are
back over it with the fix in. The durable answer is asking **"what version is the catalogue?"**
before downloading it — **designed** in [#773](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/773)
(`docs/catalog-version-check-design.md`) and **BUILT** in
[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776): a **34-byte** probe of
`catalog_snapshot_age()` before the **3.4 MB** download, both measured live, with 8 tests and
**no SQL for the owner** (the function already exists and is already granted to `anon`).

🔴 **#776 IS CONFLICTED AND IS THE ONE TO UNBLOCK.** It is the durable fix for the thing that
generated the quota email, it is finished, and it is sitting at `mergeable_state: dirty`. ⚠️ It
touches `Data/*.swift`, so it is **NOT auto-merge class** — it needs owner OK plus a device check,
and its own author says why: *"when this code goes wrong the symptom is not a crash but an app
showing nothing or showing old content."* The device check is two minutes — reopen with nothing
changed (content still right), then reopen after a content merge (new content arrives).

⚠️ **It does not fix the size, only the frequency.** When anything changes the app still downloads
all 1,552 tours. The larger step after it is dropping `transcriptText` (**38%** of the payload) and
`longDescription` (**18%**) — deferred deliberately, as a breaking catalogue change.

**🔴 A DEAD TIKTOK LINK NEEDS RE-SHARING (2026-08-27).** `https://www.tiktok.com/t/ZP8vkb5bP/`, the twentieth of the "SF Architecture" batch, resolves to a real id (`@aggie.sanfrancisco/video/7660328152421387534`) and then fails everywhere: an empty oEmbed shell on three spaced attempts (no `thumbnail_url`), and a 367 KB *"Video currently unavailable"* page with zero `og:` tags. No caption means no subject and no location; no thumbnail means no hero, and a pin with no hero cannot ship. **Nothing on our side recovers it — only the owner re-sharing a live link.** ⚠️ It is an ordinary `/video/` post that has gone, **not** a `/photo/` carousel; that limitation is separate and permanent.


Nothing here can be done from a session. Ordered by what blocks the most.

| Item | Why it matters | State |
|---|---|---|
| ~~**App Store 1.1 review**~~ | ✅ **APPROVED AND LIVE** — owner-reported 2026-08-28. Submitted 2026-08-18 03:22 UTC on build 66. See § 1d. | ✅ Done |
| **Stripe platform review** | **Round 5 submitted 2026-09-11.** First response able to show a product: the Website URL is now the **App Store listing**, not `dozent.world`. 🔴 Two claims from rounds 1–4 had become FALSE and were removed — "no transactions processed" (one $0.99 sale on release day) and "all content is first-party" (1,717 pins credit ~343 third-party accounts). Every round is recorded verbatim in `docs/stripe-review.md` — **read it before answering anything further, and re-verify each claim against the live system first.** | ❓ Awaiting Stripe reply |
| ~~**IAP tiers blocked**~~ | ✅ **ALL 14 ARE READY TO SUBMIT (owner, 2026-08-31)** — the nine that had sat in `MISSING_METADATA` since August, plus four new ones (**599 / 799 / 1299 / 1799**). SQL applied, products created, screenshots uploaded, all added for review. **They ride with the 1.1.1 submission.** Two findings, both now in the docs: **the review screenshot must be 1242×2208** (the 5.5″ size — 1320×2868 and 1290×2796 were both refused, and CLAUDE.md had the wrong value recorded), and **one image covers all fourteen** — Apple wants to see where the purchase appears, not what it costs, so the per-price screenshot rule was this project's own over-caution. | ✅ Done |
| **App Store badge: white or black** | The **white** badge shipped on `dozent.world` (Apple's recommendation for dark grounds). The **black** variant carries a white hairline border and sits more quietly on the site's black. Both are Apple artwork, both in guidelines. Comparison rendered and sent 2026-09-11. **One-line change either way.** | 🟡 Cosmetic, owner's call |
| **Apple tax / banking forms** | Complete in App Store Connect → Business → Agreements, Tax, and Banking? **No API — cannot be checked from a session.** Changes nothing at one sale (~$0.84 net, far below Apple's threshold) but would quietly block payment once volume builds. | 🟡 Owner check owed |
| **EU trader declaration** | App declared **non-trader** while selling IAP tiers into EU cities. Declaring trader publishes an address. | 🔴 Decision owed |
| **LLC vs sole proprietor** | Gates the Stripe payout path, and collapses the EU-trader and the AHWY/EHKY-initials trade-offs at once. | 🔴 Decision owed |
| **Unique usernames — 9 choices** | Owner requirement 2026-09-12: *"every user [must] have a unique username."* **Design written: `docs/usernames-design.md`** — nothing built, no SQL. Recommends a `handle` beside the unchanged display name, unique per `(platform, handle)` (forced by live data: **19 creators are pinned under the same handle on two platforms**), automatic handles for all 416 rows (dry-run clean on live data), pinned handles reserved against impersonation. **No account deleted, merged or renamed.** Also corrects the `isPrivate` finding: "private" means approval-gated follows + hidden follower lists (`social.sql`), never a hidden profile; **3** private makers, not 2. "Go with the recommendations" is a complete answer. | 🟡 Owner choices owed |

### SQL pastes owed (Supabase SQL Editor, project **Dozent**)

✅ **Applied:** `add_country.sql` (Countries row live) · `restore_catalog_keys.sql` (places, priceTier,
isPrivate restored 2026-08-20) · **`pull_la_duplicates_260830.sql` (owner ran it 2026-08-30 —
verified against the live RPC, not the SQL Editor's success line: all four deleted rows gone, all
three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` and `isPrivate` both intact. **Nothing is owed here — do not ask again.**)** ·
**`catalog_snapshot.sql` (APPLIED — measured live 2026-09-07, not reported by anyone. Nothing is
owed here; do not ask the owner to paste it again.)**

🔴 **THE `catalog_snapshot.sql` CORRECTION, because this file said the opposite for a day and a
session repeated it to the owner.** Measured against the live database rather than inferred:
**all three of the migration's functions exist** — `catalog_snapshot_age` (200, reporting a refresh
at **21:44 UTC**, i.e. the seed from #743's own merge), `refresh_catalog_snapshot` (401 to anon,
which is correct — the seed calls it), and `get_catalog_built` (the builder, renamed aside).
**`get_catalog_built` still returns `57014 canceling statement due to statement timeout`** — and
that is the migration WORKING, not failing: the slow builder now runs once per seed, and nothing
serves it to a phone. **`get_catalog()` itself returned 200 on 14 of 14 calls**, TTFB **1.38–2.35 s**. ⚠️ **That 14/14 was a lucky window and is superseded — see the #742 row above: a longer sample puts it at roughly 1 failure in 10.**
⚠️ **The "sub-second" expectation in the session-146 note was optimistic and should not be read as a
failure signal on its own** — the payload is **10.6 MB**, of which ~0.5 s is transfer; a single-row
lookup of a 10.6 MB `jsonb` value out of TOAST is not free. **The signal that the fix landed is that
the builder times out and the served endpoint does not.** ⚠️ **The second half of that criterion does NOT hold: the served endpoint still times out on roughly 1 call in 8.** The builder moving off the request path is real; the endpoint being reliable is not yet true. ⚠️ **A second, independent 20-call sample the same morning agrees (3 failures in 20), and its latency band is what identifies this as the SAME ceiling rather than a new fault:** successes ran **0.75–5.8 s** TTFB while **every failure landed at 4.3–4.8 s**, still sitting on the anon statement timeout exactly as the pre-fix builder did.

🔴 **RE-MEASURED 2026-09-08 — THE FAILURE RATE HAS GONE BACK UP, AND THERE IS A MECHANISM THAT
PREDICTS IT WILL KEEP GOING UP.** Three unbiased samples across half an hour, all against
`get_catalog()`, the source the app reads **first**:

| Window (UTC) | Result | Failure TTFB |
|---|---|---|
| 21:53–21:55 (≈5 min after a snapshot refresh) | **9 fail / 20** | 4.6–9.6 s |
| 21:59–22:00 | **5 fail / 20** | 3.7–6.0 s |
| earlier pass | **3 fail / 8** | 4.5–5.6 s |

**Pooled: 17 of 52 ≈ 33%.** Excluding the window just after a refresh (the documented transient
class): **8 of 32 = 25%.** Either figure is far above the **~1 in 8** recorded above from earlier
the same day, and the higher one matches the **pre-fix** rate (4 in 12). Every failure is
`500 / 57014 canceling statement due to statement timeout`.

**The snapshot is genuinely in use throughout** — `catalog_snapshot_age()` returned 200 with a
timestamp minutes old in the same passes — so this is **not** the paste being lost, and #742 is not
broken. ⚠️ **The mechanism is that the snapshot ROW keeps growing.** The payload measured **10.88 MB**
today against **10.6 MB** when the fix was assessed, because the catalogue went from ~1,168 to
**1,426 pins** in between. `get_catalog()` is a single-row lookup of one `jsonb` value out of TOAST,
and that read is already sitting *on* the anon statement timeout — so **every content batch pushes
it further over.** Successes have drifted later too (2.1–6.8 s TTFB today against 0.75–5.8 s before).

**What this means in practice, stated plainly:** users are not stranded — `RemoteCatalogLoader`
falls through to the gh-pages mirror, which is healthy (**11.7 MB, HTTP 200, 0.84 s**) and
byte-current with `main`. The cost is that a third of cold launches take the slow path.
**Do not report this as fixed.** ⚠️ **And do NOT reach for gzip — it is already on, and checking
took one command:** with `Accept-Encoding: gzip` the same call returns **3.6 MB instead of 10.9 MB**
(`content-encoding: gzip` in the response), and `URLSession` sends that header by default, so the
app is already getting the compressed body. **Compression cannot help here anyway** — the failures
are at TTFB, i.e. inside the query, before a byte is sent.

🔴 **CORRECTION 2026-09-09, AND IT IS ABOUT THE MEASUREMENT, NOT THE ENDPOINT.** A cheap probe the
next morning — the one `CLAUDE.md` § Egress now prescribes, `--compressed --max-filesize 2000` —
returned **12 of 12 OK** against yesterday's 25–33%. **That is not evidence the endpoint improved,
and must not be read as one:** yesterday's samples pulled the **whole uncompressed 10.9 MB body**
on every call, today's abort after ~2 KB. Those are different requests, so the two numbers are not
comparable. What can be said is narrow and true: **the liveness probe reports healthy right now,
and `catalog_snapshot_age()` is fresh.** ⚠️ **A plausible mechanism cuts against the paragraph above
and is untested:** if any part of serialising 10.5 MB counts inside the statement timeout, then
asking for gzip (3.4 MB) would genuinely help — which would make *"compression cannot help"* wrong.
**Do not spend the egress to settle it** (see the incident below); settle it with the timeout lever,
which costs nothing to try.

The two levers that actually address it, neither attempted yet and neither a code change:

1. **Raise the anon statement timeout** — `alter role anon set statement_timeout = '15s';` (currently
   the failures cluster at 3.7–9.6 s, so the ceiling is what they are hitting). One owner paste.
   Cheapest thing to try first, and it says immediately whether the diagnosis is right.
2. **Serve less per request** — split `linkPins` into its own RPC, or add an `If-None-Match`/ETag
   path so an unchanged catalogue is a 304. This is the durable fix, because (1) only buys headroom
   that the next few content batches will eat.

**Not** another attempt at the builder — that part of #742 is working.

| File | Unlocks | Without it |
|---|---|---|
| `backend/saved_places.sql` | Saved places syncing across devices | Saving works, stays on one device |
| `backend/places_photos.sql` | Places serving their own photographs | Optional — the app is correct without it |

