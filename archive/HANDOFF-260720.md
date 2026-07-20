# HANDOFF — 2026-07-20 (session 62, code, web)

## What shipped

**Drawer rails re-anchored to the user's location.** Owner request, verbatim:
> "The primary sort for the rails in the drawer should still be based on distance to the user's location. Especially true if the user's location is within view."

[PR #405](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/405) → `main`, squash `18b96ea`. Owner-authorized merge on green CI ("Merge it").

### The change (one function)

`HomeRailsViewModel.viewerLocation(userLocation:visibleRegion:)` — the reference
point that feeds `sortedByDistance` for the curated tag shelves and
`filteredResults` for the filter feed.

**Before:** whenever a `visibleRegion` was settled, it returned the region
**center** — so shelves ranked by wherever the map was centered, even with the
user's pin on screen.

**After:** the **user's own location is the primary anchor.**
- User known + (no settled region yet **or** region contains the user) → return `userLocation`.
- Panned away to a region that no longer shows the user → viewport center (browsing another city still ranks by what's in view, §1.5).
- No user fix → viewport center if we have one, else `nil` (callers keep catalog order).

Uses the existing antimeridian-aware `MKCoordinateRegion.contains` extension
(`Location/MKCoordinateRegion+Contains.swift`).

**Deliberately untouched:** the `Near you` ↔ `In view` rail *swap* (still on the
500 m `isPannedFar` threshold). This only changes ordering *within* shelves + the
filter feed, not which location rail is shown. `sortedByDistance`'s
decorate-sort-undecorate perf shape (from session 60) is unchanged.

### Tests

+2 in `HomeRailsViewModelTests`:
- `test_filteredResults_userInView_sortsByUserLocationNotViewportCenter` — user on screen → nearest-to-user leads even when another tour sits nearer the region center.
- `test_filteredResults_userOffScreen_sortsByViewportCenter` — user panned far away (not contained) → viewport-center fallback.

Existing `test_filteredResults_sortsByViewportCenter` (user `nil`) still holds.
`test_sim` can't run from a Linux web session → PR `ci.yml` (iOS Simulator build
+ Run unit tests) is the stand-in.

## Verification

- **CI #961 green** (iOS Simulator build + unit tests).
- **TestFlight 1.1 (16)** built + signed + uploaded via `testflight.yml`
  `workflow_dispatch` on the branch (build number = `github.run_number` = 16),
  build notes attached (What changed / What to test).

## Owed / next

- **Device check (owner):** open the drawer while the map is centered over your
  location — nearest-to-you tours should lead each tag shelf (and the results
  feed when a filter chip is active); pan to another city → shelves re-rank by
  what's in view there. Subtle change, best judged on device.
- **Branch cleanup:** `claude/rail-drawer-distance-sort-rx65l1` is merged; the
  git proxy blocks branch deletion from web sessions (403) → delete in the
  GitHub UI. Same for the docs branch `claude/docsync-rail-distance-sort` once
  its PR merges.
