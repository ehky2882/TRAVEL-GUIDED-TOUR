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
