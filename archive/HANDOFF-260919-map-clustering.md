# Handoff — 2026-09-19 · Map clustering rewritten in screen space

**PR:** [#1010](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1010), squash-merged on owner OK ("looks good! merge it") after TestFlight 176.
**Builds:** 173 (rejected at upload), 174, 175, 176.

## What the owner reported

> "now that i have a much bigger catalog, the pins on the map are overlapping and messy."

Confirmed immediately in the simulator over lower Manhattan: roughly twenty cluster
badges drawn on top of each other, several unreadable.

## The cause, which was arithmetic and not taste

`MapClustering` bucketed markers into a **lat/lon grid of `cellsAcross` cells across the
visible region** — 20 on the home map. On a 390pt-wide phone that is a **~20pt cell**,
while a `ClusterPin` is **36–44pt across**. So a badge was always about twice its own
cell, and two badges in adjacent cells necessarily overlapped. The defect scaled with
the catalogue: at 1,500 tours most cells held nothing, at ~3,600 markers most held
something.

The grid's second defect is structural and had no workaround: **two pins a few points
apart but either side of a cell line never merged at any zoom**, because bucketing is
`floor(coordinate / cellSpan)` and says nothing about distance.

⚠️ The maker map already carried the symptom as a constant: `cellsAcross: 12` with a
comment explaining that 20 cells across a *short* frame span too few points. That was
the grid being hand-corrected per surface — the sign that the unit was wrong.

## What replaced it

Greedy radius clustering in **Mercator (`MKMapPoint`) space**, radius in **screen
points**:

- Each unclaimed marker, in catalogue order, seeds a cluster and gathers every
  unclaimed marker within the radius. A grid of radius-sized cells makes each seed
  check a 3×3 neighbourhood, so a pass over the whole catalogue is linear (~3,600
  markers, memoised per zoom step).
- **Zoom is quantised to half-steps** (`zoomStep(lonSpan:mapWidth:)`) and the **whole**
  marker set is clustered **before** the viewport cull. This is what preserves the
  property the old absolute-origin grid existed to protect: a pan with no zoom change
  produces byte-identical clusters and IDs, so SwiftUI updates annotations in place.
  The cull now filters the *output*.
- Both surfaces measure their own width (`onGeometryChange`) and pass it in.
  `cellsAcross` is gone from both, and with it the maker map's hand-tuned 12.

🔴 **Mercator, not degrees, is load-bearing.** The old grid's cells were
`latSpan/20 × lonSpan/20`, which are not square on screen and differ with latitude;
`MKMapPoint` distance is proportional to screen distance at any zoom, which is the
whole claim the radius makes.

## Two owner-driven adjustments, both on device

1. **Thousands did not fit.** Four monospaced digits in a 34pt badge. From 1,000 the
   count now abbreviates like Apple Maps — `1.9k`, `12k` — **rounded down so a badge
   never overstates**, in a 38pt badge. The exact figure stays in the accessibility
   label, which call sites build from `count`.
2. **Radius 56pt → 48pt.** Owner on 175: *"maybe make it just a touch less so that
   there are a little more circles."* 48 still clears a 1k badge's 48pt halo. Below
   ~44 badges begin to overlap again, which is the floor worth knowing.

## 🔴 Build 173 was rejected, and the cause was the branch's base

`altool` 90186: *train 1.1.2 is closed*. The branch was cut from the **local** `main`,
still at `MARKETING_VERSION = 1.1.2`; `origin/main` had been on **1.1.3** since 1.1.2
released on 2026-09-14. Rebasing onto `origin/main` fixed it with no version edit.

**Branch from `origin/main`, never from the local `main`** — this checkout is shared by
many sessions and is routinely behind. Per § READ FIRST, 90186 is also *evidence*: the
train closed because Apple approved that version. Confirmed with the keyless
`itunes.apple.com/lookup` check, which returned 1.1.2, released 2026-09-14.

## Verification

- Simulator, iPhone 17 Pro: before/after over lower Manhattan, one cluster tap deeper,
  and at the furthest zoom-out.
- ⚠️ **The pinch tool was unavailable** (`xcode-select` points away from Xcode.app; the
  fix needs the owner's password). The world view was reached instead by a *temporary*
  camera override in a local build only — removed before committing, verified with
  `grep TEMP`. The same override was applied to `main` to capture the honest "before".
- CI green on the merged commit, unit tests included. New tests: pins a few points
  apart merge across an old grid line, distant pins stay separate, the radius really is
  in screen points (same pair merges at 390pt wide and separates at 2000), a pan keeps
  cluster IDs stable, every marker appears exactly once, and the `1.9k` label rounds down.

## Still open

- **MapKit will not zoom out past ~one ocean** on this map; there is no whole-globe
  view. Not caused by this change, and not investigated.
- A **place capsule** (wider than a circle) can now just touch a neighbouring circle at
  48pt. Circles never touch each other. Next step if the owner wants more circles is
  ~44pt, with that trade-off.
