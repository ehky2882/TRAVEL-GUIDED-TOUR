# HANDOFF 2026-08-20 — the Library tab jitter, and the scan behind it

Session 99. **[PR #549](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/549)**,
branch `claude/library-launch-jitter`, **open — code, awaiting owner device
review**. 7 files, all Swift. No SQL, no backend change, no catalogue change.
`test_sim` **346/346**. **TestFlight 1.1 (92)** cut from the branch with notes.

## What the owner said

> "on launch the library tab jitters. loading performance is no good"

One sentence, two independent causes. Worth separating them, because only the
first is about Library.

## Cause 1 — the Lists tab drew itself three times, every launch

`TourListService` held `myLists` / `savedLists` **in memory only**. No disk
cache. So every launch started empty and Library's `.task` filled it with
**three network round-trips awaited one after another**:

    await loadFollowing()      // may itself await loadMyMaker() first
    await listService?.loadMyLists()
    await listService?.loadSavedLists()

Each landing shifted the layout — Liked alone, then named lists inserting, then
a whole `SAVED LISTS` section appearing below them. The tab settled in the
**sum** of three queries, on screen.

Fixed three ways:

1. **A per-account snapshot on disk, hydrated synchronously in `init`.**
   `ProfileSnapshotStore<Snapshot>("lists")`, holding `myLists`, `membership`,
   `savedLists`, `savedListIds`. `AuthService` seeds `user` from the persisted
   session in *its* init, so the uid is already known when `TourListService` is
   constructed at App init.
2. **The three loads run concurrently** (`async let`), in Library *and* on the
   maker page's LISTS tab, which had the same stacked pair.
3. **Lists refresh at launch**, alongside the Me tab's existing pre-warm, so the
   first Library tap is no longer what starts the clock.

### 🔴 The durable rule, paid for three times now

`MakerProfileService.myMaker` / `MakerTourService.myTours` (session 58) and the
follow counts + follow list (sessions 58, 63) were each fixed **exactly this
way**. Lists were the one kept-things surface still waiting on the network to
learn its own shape.

> **Any `@Observable` service whose empty state changes a screen's LAYOUT needs
> a disk snapshot hydrated at init.** An in-memory cache fixes warm re-entry and
> does nothing at all for a cold launch.

### Two deliberate choices in the cache

- **`hasLoadedSaves` is NOT restored.** It is what makes a shared-list screen
  fetch save state once per launch (`TourListDetailView:161` guards on
  `!hasLoadedSaves`). Restoring it true would let a bookmark changed on another
  device stay wrong until Library was opened. The saved *ids* do hydrate, so the
  bookmark draws right immediately, and that one fetch corrects them.
- **`clear()` drops the account's cached copy too.** Sign-out already wipes
  synced data from the device (PR #283); a list cache left behind would outlive
  it.

⚠️ **Every write path calls `persistSnapshot()` — a new one needs a call too**,
or the next launch renders a layout the user already changed. There are ten
call sites today.

## Cause 2 — every lookup was scanning 1,418 tours

`DataService.tour(by:)` was `tours.first { $0.id == id }`. So were
`maker(by:)`, `place(by:)`, and `tours(by:)` (a full `filter`). These are read
**per row on every body evaluation** from ~20 sites — including the
**always-mounted mini-player** (`BottomModuleRoot`) and the Home drawer's
continue-listening row.

Library alone ran dozens per frame:

- `savedTours` — a compactMap of scans, **re-derived three times** for the one
  Liked row (count, cover, cover category)
- each saved-place row resolved `rankedTours(at:)` **three times** (cover,
  category, subtitle)
- each followed-maker row filtered the **entire catalog just to count**

Now `tourById` / `makerById` / `placeById` / `toursByMakerId`, rebuilt only when
the catalog itself changes; and the rows that were re-deriving one value resolve
it once. **This is app-wide, not Library-specific** — Home and the maker page
get it too.

### 🔴 The trap indexing introduces

Staleness, and it looks like **missing content rather than a bug**: an index not
rebuilt when the catalog changes returns nil for a row plainly on screen. Every
mutation now goes through one door — `applyCatalog` / `applyMakers` /
`setPlaces` — and `DataServiceLookupTests` pins that a refresh, a **failed**
refresh, and an `applyLocalMaker` patch each leave the indexes agreeing with the
catalog. `tours(by:)` is tested to keep **catalog order**, which a dictionary
does not give you for free.

## ⚠️ A silent-failure risk worth knowing

**`JSONEncoder` writes `[UUID: Set<UUID>]` as a flat alternating array, not an
object.** The snapshot's `membership` is exactly that shape. If it ever stopped
round-tripping, membership would hydrate empty and **every bookmark glyph in
every rail would draw un-saved on the first frame and then flip** — with no
error anywhere. `TourListService.Snapshot` is internal rather than private
specifically so a test round-trips the real type.

## What is verified, and what is not

- `test_sim` **346/346**, 0 failed. 12 new tests.
- Simulator: Home renders 68 tours in view with place capsules and maker names
  (a path that is nothing but these lookups); Library renders correctly.
- ⚠️ **The jitter itself could NOT be reproduced in the simulator** — it holds
  no session, so there are no lists to pop in. The fix is reasoned from the code
  and pinned by tests, **not watched**. Device confirmation on a signed-in
  account is owed, and is what build 92 is for.

## ⚠️ Process note that recurred immediately

`session_show_defaults` pointed at `/Users/EY/Desktop/TRAVEL GUIDED TOUR/` —
**the other clone** — and at `iPhone 16 Pro`, which no longer exists on this
machine. Building would have tested untouched code. This is already recorded
from session 97 and it happened again on the very next local session. **Set both
before the first build of any session.**
