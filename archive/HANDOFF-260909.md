# HANDOFF — 2026-09-09 (session 152)

**Thirty-six `@urbanistariel` link pins — [PR #767](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/767), open.**

The owner sent 36 TikTok short links with no further instruction than *"new tour uploads"*.
All 36 resolved, none was already pinned, **36 ship**. `linkPins` 1,453 → 1,489; makers,
tours and the place count otherwise unchanged.

## What the batch needed that the runbook does not do for you

**12 of the 36 links carried no location.** `make-link-pin.py` refuses a batch with a missing
coordinate — correctly, since a pin with none sits in the Gulf of Guinea and validates — so
those twelve had to be located from the caption before anything could be minted. Each derived
point was checked against **the bounding box of the city its own caption names**, the check
#762 added after a New York geocode matched a village 250 km upstate. **12/12 in box; 36/36
reverse-geocoded at zoom 18.**

⚠️ **Two geocodes missed on the first query and neither was the place's fault** — `Arezzo,
Province of Arezzo, Italy` resolves to nothing (`Arezzo, Italy` resolves instantly) and the
Ghostbusters firehouse has to be asked for as **`FDNY Ladder 8`**, not `Hook and Ladder 8`.
Seventh batch running where re-querying was the whole fix; the runbook's own note holds.

## The stack cap, and why nothing new was invented

Three of these posts are about the **Cathedral of St. John the Divine** and one about the
**Morgan Library**. Both sites already carry five entries, so the three would have made an
8-deep group against `TourSetMap.maxStacked = 3` — `prefix(3)` drops the rest silently.

Both are **already places**, so no editorial approval was owed and nothing was created: the four
pins take the place's own coordinate (how all ten existing members are wired) and join its
`tourIds`. **Cathedral 5 → 8 members, Morgan 5 → 6.** The joiner asserts `kind == "link"` and
`triggerMode == "manual"` before moving anything and re-asserts every member's coordinate
afterwards, so the geofenced Atlas tour at the cathedral is provably unmoved.

🔴 **Membership alone is what collapses the marker.** `MapMarkers.markers(for:places:)` drops a
member's own pin regardless of where it sits, so the coordinate move is convention (and what
`validate-tours.swift` requires), not the mechanism.

## Two titles were wrong until the picture was opened

Three retitles were mechanical — an entry on the same spot already held the name (`East Side
Gallery` 21 m, `Cathedral of St. John the Divine` 30 m, `Conwell Coffee Hall` 17 m). **The other
two came out of the hero review and would have shipped otherwise:**

- **`Inside La Sagrada Família`** — the hero is a distant skyline shot. *Inside* was simply
  false. Ships as `Why Millions Visit La Sagrada Família`, which also stays distinct from Atlas
  Studio BCN's `Sagrada Família` 90 m away.
- **`Wall Street's Slave Market`** — a specific historical claim the caption never makes; it says
  only *"what was here before it became a center of finance"*, and the frame's subtitle reads
  *"but both the wall and the black…"*. The creator's own title card, **`The Dark Secret of Wall
  Street`**, is the honest version and is what ships.

⚠️ **Both were renamed before upload**, so hero filenames match and no live URL was rewritten —
the #567 rule costs nothing if the mistake is caught before the push.

## Verification

- `validate-tours-mirror.py`: **selftest 32/32, control clean, 0 errors / 0 warnings** across
  1,552 tours + 1,489 pins + 137 places. `make-link-pin.py --selftest` **71/71** — Pillow is
  absent from a fresh container and a bare run reports **62/62, which reads as a pass**.
- **All 36 ids reproduce** from `atlas-tour:link:<url>` / `atlas-stop:link:<url>`, and the maker
  id from `atlas-maker:tiktok:@urbanistariel`, so the existing creator row is kept.
- **0 hero paths pre-existed** — checked against the gh-pages tree *and* 36 live HTTP requests.
  The handle suffix again prevented three overwrites (`east-side-gallery`, `chicago-water-tower`,
  `conwell-coffee-hall` are all live heroes of other entries).
- The avatar regenerated **byte-identically** to the live file and was excluded from the push.
- gh-pages `1d42a4b`: `git ls-remote` re-read in the same command as the push, **36 additions,
  0 deletions, nothing outside `images/`**.
- ✅ **All 36 heroes opened and read against their captions — zero wrong subjects.**

## `main` moved under this branch, again

**#766 merged while this batch was being built**, trimming `STATUS.md` from 219 KB to 69 KB.
The board entry had already been committed against the pre-trim file, so merging would have
resurrected 150 KB of archived history. Resolved the documented way — **main's file taken
wholesale (`git show origin/main:STATUS.md`) and the entry re-applied to it**, never
hand-resolved. Third batch running where the hazard is a parallel session rather than the work.

## Left open

- ⚠️ **The Pages deploy had not published when the PR was opened** — all 36 hero URLs still 404.
  The run is `in_progress`, not cancelled; the bytes must be confirmed live before merge.
- ⚠️ **`The Dark Secret of Wall Street` sits exactly at the cap with no headroom**, 21 m from
  `The Red Room at One Wall Street` and 60 m from `The Buttonwood Tree at the NYSE`. A fourth
  link there is permanently untappable. **Owner's call whether it becomes a place.**
- ⚠️ **St. John the Divine is now the busiest place in the catalogue at 8 members.**
- 🔴 **[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) is still open** with 54
  pins, and still carries the Tower Bridge follow-up #758 left it.

---

## Post-merge verification (added after the squash)

**Merged as `48f2574`.** Everything below was measured after the merge, not predicted before it.

| System | Reading |
|---|---|
| `main` | 1,552 tours · **1,489 pins** · 353 makers · 137 places; all 36 present; 0 pins inside `tours` |
| gh-pages mirror | **blob-identical to `main`** (`f47de68a` both sides) — the CDN still lagged, as always |
| Pages deploy | run 857 completed; **36/36 hero URLs sha256-identical** to the local files |
| Supabase `get_catalog` | 200, 10.9 MB, TTFB ~2.0 s; **1,489 pins, all 36 present**, both places at 8 and 6 members |
| `check-image-duplicates.py --pins` | stamp from this run; 1,481 images, no suspicious duplicates; shared-URL half 0 errors / 210 documented reuses |

⚠️ **The Supabase seed took 13 minutes to land** (merge 00:22 UTC, RPC still serving 1,453 pins at
00:34, correct at 00:35). Polled to a condition rather than slept on — an interval that happened
to end at 00:34 would have reported the batch missing from the primary source.

## 🔴 A gotcha that reads exactly like "nothing shipped"

Comparing pin ids against the live RPC **case-sensitively reports 0 of 36 present**, and the hero
URL check then reports all 36 mismatched, because every lookup missed. Nothing was wrong:
**Postgres renders `uuid` lowercase and the catalogue stores it uppercase.** Compare
`.upper()` on both sides. Case-insensitively it is 36/36, with **0 title or hero-URL differences
against the merged catalogue**.

Same shape as `isPrivate`, checked in the same pass and also a false alarm: it is present on
**0 of 1,553 tours** because it is a **`Maker`** field, and it is present on **375 of 375 makers**.
Both of these look like a dropped key and neither is one — the § "Reading a check's result"
habit applies to a check you wrote thirty seconds ago, not only to the ones in `scripts/`.

---

## Three places, on owner instruction — [#769](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/769), merged `589dc70`

**places 137 → 140.** `tours`, `linkPins` and `makers` byte-identical.

| Place | Members | Coordinate from |
|---|---|---|
| Trinity Church · Broadway at Wall Street | 3 | the Atlas tour (`manual`) |
| Madison Square Garden · 4 Pennsylvania Plaza | 3 | the Atlas tour (**`geofenced`**) |
| Penn Station · 234 West 31st Street | 4 | **OSM's own station node** — no Atlas tour exists |

Live on the RPC at 02:43 UTC, **~10 minutes after the merge**: all three present, all ten
members on their place's point, addresses and heroes as authored.

## 🔴 The correction that mattered more than the places

I told the owner that Wall Street, Trinity Church and Madison Square Garden were **at or over
the map's stack cap**, and that a fourth entry at Wall Street would be permanently untappable.
**That was wrong, and it was my own check that was wrong, not the data.**

The reading came from a **65 m proximity sweep** — the tool earlier sessions use to *find
candidates*. It is not the cap. `TourSetMap` stacks place cards for markers that share a
cluster cell, and with `MapClustering.cellsAcross = 20` at `buildingScaleSpan` (0.0006°, about
65 m across) **a cell is roughly 3 m**. Anything 20–85 m apart separates by zoom and stays
reachable.

Measured on exact coincidence — the case no camera can separate — **the catalogue has 0 loose
groups over the cap and 0 exactly at it**, before the change and after it.

⚠️ **What this does NOT retract:** the St. John the Divine and Morgan joins in #767. Those three
pins shared one identical derived coordinate, which is the real defect.

**The habit:** when a sweep says "at the cap", say which test produced it. A proximity ball is a
candidate finder; the cap is a cluster-cell question, and the two differ by a factor of twenty.

## Two smaller things worth keeping

- 🔴 **A place's member invariant is FIRST-STOP equality, not centroid.** A `multiStop` walk's
  centroid is the mean of its stops, so a centroid assertion fails for **26 live members** —
  correctly: the walk begins at its place and then leaves it. My first builder asserted centroid
  and refused to run, which is the assertion working.
- **An anchorless place needs a coordinate from outside the catalogue.** Penn Station has no
  Atlas tour (57 of the 139 live places are link pins only), so its point came from OSM's
  `New York Penn Station` node rather than from whichever pin happened to be first — and two of
  the four pins already sat on it exactly. ⚠️ **The Eagle moved 157 m and the Mosaics 136 m**;
  that is the honest cost of collapsing a two-block station onto one marker, and the owner was
  told rather than left to find it.

## Left open

- **`Penn Station's Lamppost at St. John the Divine`** is not a Penn Station member and should not
  become one: the lamppost was moved to the cathedral, and the pin belongs to that place.
- **Wall Street was left alone** — the owner said "leave it for now, we'll revisit" once the cap
  claim was corrected. `The Red Room at One Wall Street` and `The Buttonwood Tree at the NYSE`
  remain their own pins.
