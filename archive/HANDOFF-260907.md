# HANDOFF — 2026-09-07 (session 147)

**The Gilder Center becomes a place — the last stack-cap finding from the Studio Gang batch, closed.**
Owner: ***"MAKE GILDER CENTER A PLACE. DONT WORRY ABOUT WEAK HEROES."*** Both halves applied.
**Places 129 → 130.** Content only — no Swift, no SQL, no gh-pages push, no build.

---

## What shipped

One place, three members, all link pins by three different creators:

| Member | Creator | Moved |
|---|---|---|
| `The Gilder Center` | TikTok `@archiwhisperer` | 3.44 cm |
| `Inside the Gilder Center` | TikTok `@archimarathon` | **0.00 cm** — already exactly on the anchor |
| `The Gilder Center Canyon` | Instagram `@studiogang` | 3.44 cm |

Diff **24 insertions / 8 deletions**, and **every one of the 8 deletions is a coordinate line** —
2 pins × 4 fields (`latitude`, `longitude`, `centroidLatitude`, `centroidLongitude`). `tours` and
`makers` are **byte-identical**; the 129 existing places are unchanged as a prefix; **2 of 1,278
link pins changed**, in no field but their coordinates.

---

## 🔴 The cap is why this exists, and the checker under-reported it

The three markers sit **at most 3.44 cm apart** — which is to say, on one point. Against
`TourSetMap.maxStacked = 3` that is **exactly at the cap with no headroom**: every one renders
today, and a fourth Gilder Center link would put one permanently out of reach, invisibly. Since
all three are link pins by different creators, the cap bites on the Home map and on every place
and list map rather than on a creator page.

⚠️ **`check-place-candidates.py` reported this as an EXACT pair plus a separate NEAR pair, not a
group of three** — the third pin differs in the **7th decimal** (the documented CalAcademy rounding
artifact), which defeats the EXACT tier's equality test. That is why resolving it moves **two**
tiers at once: **EXACT 20 → 19 and NEAR 60 → 59**, and the report diff proves it removed exactly
the Gilder EXACT pair and the 0 m NEAR pair and **added nothing** — no group was manufactured and
nothing was nudged apart. ⚠️ It still exits 1 on the 19 belonging to other batches, so **a clean
exit is not the expected state today**.

---

## The anchor was proved, not assumed

**`40.7815797, -73.9746411` is OSM node `10172954431`** — the forward geocode returns it at
**0.0 m** and the reverse names the building exactly. All three markers had independently converged
on it, which is why one of them did not have to move at all. Every member was asserted `manual`
before anything was written, so no geofence is disturbed; there is no Atlas tour here, so the
"pin moves, never the tour" question never arose.

### ⚠️ The address is `200 Central Park West`, and the obvious answer was recollection

I first reached for **415 Columbus Avenue** — the Gilder Center's own published street entrance.
It is not in OSM at that point: an unbounded query returned three hits **24 km, 85 km and 483 km**
from the site, the classic unbounded-geocode trap. Probing the Columbus Avenue side directly, OSM
assigns **`200 Central Park West`** to the whole museum campus at every probe. That is what ships —
**corroborated by geocoding rather than taken from it**, and it is also the address the enclosing
AMNH place carries.

---

## 🔴 A bug I introduced and caught by hand — the mirror cannot see it

The assembler's first run wrote **`centerLatitude` / `centerLongitude`**, fields that **do not exist
on `Tour`** (`Models/Tour.swift:259` — the real names are `centroidLatitude` / `centroidLongitude`),
and left the real centroid fields **stale at the old coordinate**. So two pins would have shipped
with a stop at the anchor and a centroid 3.4 cm away, plus two invented keys.

**`validate-tours-mirror.py` passed it at 0 errors.** Centroid-vs-stop agreement is a documented
mirror blind spot that **`validate-tours.swift` does check** — so this would very likely have
failed CI, on a content PR, after the docs were written.

What caught it was reading the diff rather than the validator: three unexplained lines that had no
business being in a coordinate-only change. Two hard post-conditions now sit in the assembler:

- **no member gains or loses a top-level key** (the key set is taken from an untouched pin), and
- **every member's centroid mirrors its stop.**

And because the harness below confirms the mirror misses it, the property is now **asserted
directly** — on the three members (0 drift) and **catalogue-wide across all 2,758 single-stop
entries (0 drift)**.

⚠️ **2,830 is the TOTAL entry count, not the single-stop one.** 2,758 entries carry one stop; the
other 72 are walks, where a centroid legitimately differs from stop 0 and this rule does not apply.
An earlier revision of this file said "2,830 single-stop entries" — the finding was right, the label
was not, and it is exactly the kind of number a later session quotes.

---

## The sweep went past the checker's group

400 m around the anchor, by distance and by full text. Two things are in range and **both are
correctly excluded**:

- **The AMNH cluster at 176.1 m** — six members, and ✅ **the owner ruled in session 140 that the
  Gilder Center stays separate from it** (*"Gilder center keep separate"*). It is AMNH's own wing
  with its own entrance; that decision is **closed** and a future audit will flag it again.
- One unrelated pin at **394 m**.

⚠️ **Flagged, not acted on: the `@poche_space` pin `Poché - Studio Gang | episode 2 of 3`** is
substantively about the Gilder Center — its whole `longDescription` is the Gilder Center and its
hero file is literally `amnh-gilder-center_hero.webp` — yet it sits at the **AMNH** coordinate and
is one of that place's six members. Moving it would take AMNH 6 → 5, so it is the **owner's call**,
not mine. Since its hero is a near-black podcast title card rather than a photograph, **nothing
photographic is lost by leaving it where it is.**

---

## The hero, and the trade-off stated

All three candidates were **rendered and looked at**, never chosen by filename. It takes
**`@studiogang`'s canyon** — the concrete cut into curved cave walls with irregular openings at
every level, bridges crossing the gap, daylight from above. **No people, no burned-in text.**

⚠️ **Stated trade-off: `@archimarathon`'s frame is the finer picture** and was rejected only because
it carries a clipped subtitle across the bottom. One line swaps it.
⚠️ **None of the three is an exterior** — all three creators shot the atrium, which is what the
building is famous for; there is no exterior of the Gilder Center anywhere in the catalogue.

**The hero is borrowed from a member and that is structural** — every member is a link pin with an
**empty gallery** and there is no Atlas tour at this site, so no third photograph of it exists (the
documented Waterlooplein / Legion of Honor case the owner has closed). **Do not go sourcing a
replacement.** Borrowed-hero count **re-derived, not carried forward: 54 of 130**.

✅ **Weak heroes are CLOSED for this batch — owner: *"DONT WORRY ABOUT WEAK HEROES."* Do not
re-raise them.**

---

## ⚠️ The two members disagree on the opening date, and the copy takes neither side blindly

`@studiogang`'s caption says **"February 17, 2023"**; the `@poche_space` pin says **"Completed in
May 2023"**. Verified externally rather than picked: the Gilder Center **opened to the public on
4 May 2023**, and the February date is a countdown to an opening that slipped. The copy states
**4 May 2023** and **does not repeat February anywhere** — the creator's words stay verbatim in
their own `longDescription` (the Schweizer convention).

Everything else in the description is what the members themselves carry, plus what is uncontested:
Studio Gang, 230,000 square feet, the atrium's cave-like concrete, the building as connective
tissue stitching a campus that had accumulated for more than 150 years across four city blocks.
**No visitor figure, no cost figure, and none of the members' superlatives.**

⚠️ **The place name `The Gilder Center` matches a member's title exactly** — the building has one
name, so the parent matches a child (the One Times Square / Tin Building call). **Do not "fix" it.**

---

## Verification

- **`Tours.json` byte-stable under a Python re-dump before AND after editing.**
- Mirror **self-tested 27/27 with a clean control**, then **0 errors, 0 warnings across 1,552 tours
  + 1,278 pins + 130 places**, **exit code read directly, never through a pipe**.
- 🔴 **15 place-layer faults injected against THIS place specifically — 14 caught, control clean
  before and after.** The harness counts **errors AND warnings** (the session-141 bug) and reads
  `check()`'s **`(errors, warnings)` TUPLE** rather than mistaking it for an exit code (the
  session-142 false pass), injecting **in memory** rather than onto disk. ⚠️ **The one miss is the
  centroid-mirror blind spot above, deliberately included to confirm it is still blind** — and it
  is asserted directly instead, on the members and catalogue-wide.
- Faults caught: the place drifting off its members in latitude and in longitude; first and last
  member nudged 55 m; dropped to one member; an unknown tour id; an empty name; a malformed hero
  URL; the hero repeated in its own gallery; latitude out of range; a duplicate place id; two
  members set to the same pin; a member also claimed by the AMNH place; a member that is not a real
  entry at all.
- Place id `uuid5(NAMESPACE_URL, "atlas-place:new-york:the-gilder-center")`, minted **lowercase**,
  the scheme **reverse-verified against the existing places** before minting, **0 collisions**.
- **0** duplicate place ids · **0** tours claimed by two places · **0** places with fewer than two
  members · **0** members off their place's coordinate.
- 🎉 **`check-place-candidates.py` EXACT 20 → 19 and NEAR 60 → 59**, report diff proving it removes
  exactly the Gilder pair plus the 0 m NEAR pair and **adds nothing**.
- `seed_from_toursjson.py` clean at **346 / 2,830 / 3,202 / 130**; **0 `images//`** in the catalogue
  *or* the SQL.
- Place hero live **200**, 44,138 bytes, **hash-matched against the bytes actually looked at**.
- ⚠️ **`check-image-duplicates.py` deliberately NOT run, and that is not a gap** — no image was
  added and no image URL changed (`tours` byte-identical, and the two moved pins differ in no field
  but their coordinates). The hero is now used exactly twice, in its own pin and as the place hero,
  which is the documented tier-1 shape rather than a collision.
- ⚠️ **Nothing compiled locally** — no Swift toolchain in a Linux web session, so **CI on the PR is
  the only compile check.**

---

## Earlier in the same session

- **[#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740) merged** (squash `62b662b4`) —
  four Miami / Little Rock places, **places 125 → 129** — and **verified against the live systems
  rather than the merge's success line**: the RPC serves **129 places** with all four present and
  correct, #739's four still served, **0 pins wrongly inside `tours`**, **0 members off their place
  coordinate**, the session-99 dropped-key check clean, and all four hero URLs live 200. The
  gh-pages mirror converged ~2 minutes later.
- 🔴 **My first mirror-vs-RPC comparison reported all four places as MISMATCH, and the bug was
  mine** — `Tours.json` stores member UUIDs **uppercase** while Postgres returns them **lowercase**,
  and the orderings differ. **This is the documented session-99 trap and I walked into it.**
  Comparing `sorted(x.lower() ...)` gave 4/4 OK, identical place-id sets across all 129, and 0
  membership differences. **Compare ids case-insensitively.**
- ⚠️ **The RPC returns `500 / 57014 canceling statement due to statement timeout` while its own seed
  is applying** — expected during a publish, not an outage. Poll through it.
- **[#741](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/741) merged** (squash `570ee7dc`) —
  `STATUS.md` flipped #740 OPEN → MERGED.
- ⚠️ **The check-runs API lagged on #741 and reported `in_progress` after the job had moved on** —
  reading the workflow-jobs API showed it genuinely running (simulator prep 5m17s). **Distinguish
  "slow" from "stuck" by reading jobs, not check runs.**

---

## ⚠️ `main` moved during this session, and the rebase is worth recording

**[#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742) merged** (squash `9eaabdd1`) while
this place was being verified — a parallel session's fix for the RPC materialisation failure (a torn
read at roughly a 33% failure rate). It touches **9 files including `backend/seed_from_toursjson.py`,
`scripts/check-catalog-keys.py`, `CLAUDE.md`, `ROADMAP.md`, `STATUS.md` and `archive/README.md`** —
every doc file this session had to write.

**It does NOT touch `Tours.json`**, and the baseline file is **byte-identical on both bases**
(`c061b988b53b652b` either side), so the build carried over with nothing to redo. But **every check
was re-run on the moved base anyway** rather than assumed: mirror **27/27 then 0/0 across
1,552 + 1,278 + 130**, the **15 faults 14/15 with clean controls both sides**, the checker's
**20 → 19 / 60 → 59** with the same report diff, and the seed clean on the **new** script at
**346 / 2,830 / 3,202 / 130**. The docs were then written against `main`'s versions, not the
pre-merge ones.

---

## ✅ Merged, and verified against the live systems

**[#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) merged** (squash `f6c1815e`) on
green CI — **Validate Tours.json** (the authoritative Swift validator), **Build (iOS Simulator)** and
**Run unit tests**, all three. The squash was then **checked to carry real content** — 372 insertions
/ 10 deletions across 6 files — because "Pull Request successfully merged" is not evidence anything
landed (#629 shipped an empty commit under exactly that line).

`Publish catalog` run 194 completed **success** in under three minutes, and only then was the live
check run. **The Supabase RPC — the source the app reads FIRST — and the gh-pages mirror each serve
130 places**, with The Gilder Center present, its **three members all on the place coordinate**,
**0** members off their place coordinate catalogue-wide, and **0** link pins wrongly inside `tours`.
Session-99 dropped-key check clean (`priceTier` 1,553 · `isPrivate` 368 · `country` 1,552).

⚠️ **Two count differences that are both correct and both worth recognising on sight.** The RPC
reads **1,553 tours / 368 makers** against the catalogue's 1,552 / 346 — the documented `Zxxx` test
tour plus upsert-only maker accumulation, so **assert on link-pin counts (1,278, exact), never on
maker totals**. And the **mirror reports `priceTier` and `isPrivate` at 0**, which is *not* a dropped
key: both live only in Postgres by design, so a content re-seed can never wipe pricing.

### Owner action, unblocked and ordered

⚠️ **`backend/catalog_snapshot.sql` still needs the owner to paste it.** The merge landed first, so
the ordering hazard is already satisfied — the paste is now safe.

🔴 **Read the LATENCY, not a pass/fail count** — and this session is the worked example. The RPC
answered **200 on the first attempt, in 4.7 s**. One clean sample proves nothing: a 33%-failure
endpoint comes back 8/8 clean about **4% of the time**, which is exactly how this gets closed as
"cannot reproduce" by a later session. It already did once. **Seconds means the snapshot is not
being served** — after the migration `get_catalog()` should be a sub-second lookup. Corroborated
independently by `scripts/check-catalog-keys.py`, which reports **"catalog snapshot: not in use
(built per request)"** beside its 130 places.

### ⚠️ A monitor that watched for the publish job stayed silent through its own success

The poll loop shelled `curl` at `api.github.com` and matched on `"completed *"`. It emitted nothing
for fifteen minutes while the run finished in under three, because **`curl` to `api.github.com`
returns a JSON error body from this container** — a trap already recorded in `CLAUDE.md` from
session 99 — so the parse yielded a string no branch matched and the loop slept on. **Silence read
as "still running".** Poll GitHub through the MCP tools; if a poll loop must be shelled, emit on
*every* terminal state **and on the unrecognised case**, never only on success.

**[#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743)** (docs-only, same parallel
session) records that on the board.
