# Atlas — Handoff Notes (2026-06-06, session 23)

Implementation session — **place/location search added to Search**.
One feature, one branch (`claude/place-search-260606`), squash-merged to
`main` after owner sim review. **No build bump (stays 33). 88/88 tests
pass (4 new).** Owner explicitly lifted the prior "Home map camera is
settled — don't touch" note for this additive change.

Files: new `Features/Search/PlaceSearchService.swift`,
`Features/Home/MapRegionGeometry.swift`,
`TRAVEL GUIDED TOURTests/MapRegionGeometryTests.swift`; edited
`Features/Search/SearchView.swift`, `Features/Home/HomeView.swift`,
`Features/Home/HomeSharedState.swift`. The branch also carried the
same-day Search-polish commit (caption typography, single-line result
rows, maker result section) that was uncommitted on `main`'s working
tree when the branch was cut.

---

## What shipped

### Place search
- **Places section in `SearchView`.** Typing a place name surfaces a
  **PLACES** group above the Makers/Tours catalog results (gold
  `mappin.and.ellipse`, BODY all-caps name, locality subtitle,
  `arrow.up.right` "out to map" affordance). Section headers now show
  whenever Places *or* Makers are present; a tours-only query stays
  headerless (unchanged behavior). Place taps are **not** recorded in
  `RecentSearch` — that history stays catalog-focused.
- **`PlaceSearchService`** — `@MainActor @Observable` wrapper around
  Apple's `MKLocalSearch` (no third-party deps, no backend — same
  MapKit/CoreLocation the app already uses). Debounced 300ms via a
  cancellable `Task`, caps at 4 results. Each `MKMapItem` is reduced to
  a `PlaceResult` (name / subtitle / region); zoom is derived from the
  placemark's `CLCircularRegion` radius (×2.2, clamped 1–50km) so a city
  zooms to city level and a landmark zooms tighter.
- **Search → map channel.** `HomeSharedState.pendingMapMove`
  (`PendingMapMove`, UUID-keyed so it's `Equatable` for `.onChange` and
  re-taps to the same place still fire). `SearchView` sets it +
  `dismiss()`; `HomeView` observes it and flies the camera. This keeps
  `cameraPosition` private to `HomeView` — no lift needed.
- **`HomeView.flyTo` / `evaluatePlaceArrival`.** Additive camera driver:
  retracts the drawer, clears any placecard, eases `cameraPosition` to
  the region. The existing recenter / pin-tap / startup paths are
  untouched. When the settled region contains no tour stops, a transient
  **"No Atlas tours here yet — Atlas tours are in New York and
  Portugal."** hint shows (auto-dismiss 6s, or on a map tap).
- **`MapRegionGeometry.anyStop(of:inside:)`** — pure helper behind the
  hint; reuses the existing antimeridian-aware
  `MKCoordinateRegion.contains`. Unit-tested (4 new tests).

## Decisions made this session (owner)
- **Empty-area UX:** go anywhere + show a "No Atlas tours here yet"
  overlay (vs. hiding far places or showing a count).
- **Layout:** a separate **Places** section above the tour results.
- **Camera constraint lifted** for this additive work (explained in
  plain terms; owner approved editing the map camera code).
- Reviewed the build in the simulator and approved shipping; deferred
  the *how* (PR / merge) to Claude.

## Worth a real-device / manual check
- **No-tours hint timing.** In the **simulator** the pill can appear a
  few seconds late on the first fly to a far, uncached region —
  MKMapView's tile streaming starves SwiftUI overlay compositing there.
  It renders correctly once it appears, and the accessibility tree shows
  it immediately. On device (Metal compositor) it should pop up promptly.
  Verify on a real device / TestFlight. Attaching the hint as a ZStack
  *sibling* of the `Map` did not composite at all — it's an `.overlay`.
- **`MPVolumeView` / AirPlay** (carried from session 22) still
  device-only.

## Not done / deferred
- Cosmetic `MKMapItem.placemark` iOS-26 deprecation warning in
  `PlaceSearchService` (kept for the per-feature zoom; the replacement
  `location`/`address`/`addressRepresentations` API shape is uncertain).
  Easy follow-up if a warning-clean build is wanted.
- No build bump; owner hasn't asked for a TestFlight cut of this work.

## How to resume
1. Session-start ritual (git/PR health + read this file).
2. Place-search lives in `Features/Search/PlaceSearchService.swift` +
   `SearchView.swift`; the map side is `HomeView.flyTo` /
   `evaluatePlaceArrival` + `HomeSharedState.pendingMapMove`.
3. See `~/.claude/.../memory/reference-atlas-sim-automation.md` for sim
   automation notes (incl. the MKMapView/SwiftUI overlay compositing
   gotcha).
