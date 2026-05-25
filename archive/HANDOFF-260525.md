# Atlas — Handoff Notes (2026-05-25)

Single-session day. Shipped PR #66, extending the bottom-module
geometry work that PR #60 introduced for the home screen across the
rest of the app. Squash-merged into `main` as `2452f52`.

---

## What shipped this session

### PR #66 — module geometry on non-Home tabs (merged)

Commit `2452f52` on `main`. 10 files, +206 / −24.

Two fixes bundled, sharing a single mechanism:

**Full-edge module on non-Home tabs.** The mini-player + tab bar
strip retains its rounded floating-island look on Home (the visual
identity PR #60 just dialed in), but everywhere else (Library /
Settings / Manage downloads / Tour Detail / Maker) it now drops the
8pt horizontal inset, drops the rounded outer corners, and lets the
tab bar background extend down through the home-indicator safe area
— with the button column padded up by the safe-area inset so taps
still clear the indicator. Reads as a flat strip flush to the screen
edges, the way the standard iOS tab bar does.

**Scroll content reserves room for the module.** Every scrollable
surface on a non-Home tab applies `.safeAreaInset(edge: .bottom)`
sized to the module's actual height. The last list row / settings
row / tour description is always reachable above the module rather
than hidden underneath it.

### Mechanism (the part that's reusable later)

- **`AtlasBottomModule.height(extendsToScreenEdges:)`** — new helper
  in `Features/Player/MiniPlayerBar.swift` (above the struct).
  Centralises the module-height math: `MiniPlayerBar.layoutHeight
  (62) + tabBarBackgroundHeight (56) + trailing`, where `trailing`
  is `floatingSideInset (8)` on Home or the device's bottom
  safe-area inset (~34pt on Face-ID phones, 0 on home-button
  devices) on non-Home. Replaces HomeView's inlined
  `floatingIslandHeight = 64 + layoutHeight` constant.

- **`\.atlasIsHomeTab` environment value** (in `Theme/AtlasSpacing.swift`,
  next to the spacing tokens). `ContentView` sets it on `tabContent`
  to `selectedTab == .home`; pushed children (`TourDetailView`,
  `MakerView`, `ManageDownloadsView`) read it to size their bottom
  inset correctly whether reached from Home or from Library.

- **`MiniPlayerBar.extendsToScreenEdges`** — when `true`, drops
  `sideInset` to 0. (Renamed the old `static let sideInset` to
  `floatingSideInset` so the helper can reference it.)

- **`AtlasTabBar.extendsToScreenEdges`** — when `true`, drops
  `horizontalInset` and `bottomCornerRadius` to 0; pads the button
  column down by the bottom safe-area inset (read via
  `UIWindowScene.windows.first.safeAreaInsets.bottom`) so buttons
  clear the home indicator while the background fills the edge.

- **TourDetailView**: `actionBarHeight` now equals
  `AtlasBottomModule.height(...) + actionBarButtonArea` where
  `actionBarButtonArea = lg + controlHeight + sm`. The trailing
  ScrollView spacer was raised from a hardcoded `xxl + lg = 72pt`
  to match `actionBarHeight` exactly — fixes the pre-existing bug
  where the last description / stop lines slid under the action bar
  on a full scroll.

### Verified in sim

iPhone 17 Pro simulator (iOS 26.5), `build_run_sim`:

- Home tab: unchanged from PR #60 — floating island, drawer overlays
  mini-player at large detent, recenter button tracks the drawer.
- Library tab: tab bar background spans full screen width (3 button
  cells each 134pt wide at x=0/134/268, total 402pt). "Nothing saved
  yet" empty state centered above the module.
- Settings tab: module full-edge; scrolled to the bottom — "All data
  stored on device" (the last About row) sits cleanly above the
  module with breathing room.
- Tour Detail (Times Square → from Home → Recently viewed banner):
  scrolled all the way down — last stop description ("3m" line at
  the end of the Location section) visible above the action bar's
  Start Tour / Save / Download row.

84/84 unit tests pass locally and on CI. CI green on all three
checks: `Validate Tours.json`, `Build (iOS Simulator)`, `Run unit
tests`.

---

## Process notes / gotchas for next session

- **Auto-merge policy is now the default for every PR (including
  Swift).** Project rule changed mid-session via commit `b06284b`
  ("docs(CLAUDE.md): auto-merge all PRs on CI green; auto-resolve
  conflicts"). The previous wait-for-owner-OK gate is gone for code
  PRs — open PR, wait for CI green, `gh pr merge --squash
  --delete-branch`. Exceptions still gated: Info.plist capability
  keys, deployment-target bumps, third-party dependencies, signing
  changes. See `CLAUDE.md` § "Merging PRs."

- **SourceKit's diagnostics lie to you after big edits.** During
  this session SourceKit reported "Cannot find 'AtlasSpacing' in
  scope" / "Cannot find 'Tour' in scope" across multiple
  same-target files immediately after each edit. Real
  `test_sim`/`build_run_sim` runs were clean. The pattern: ignore
  SourceKit's red squigglies after a multi-file edit until a fresh
  build runs.

- **NavigationLink doesn't activate via XcodeBuildMCP's `tap`.**
  The `Library` / `Me` tab buttons (plain `Button(action:…)` in
  `AtlasTabBar`) responded fine to `tap(label:)`. But every
  `NavigationLink { destination } label: { card }` in `TourListCard`
  / `LibraryView` / `MakerView`'s tour rows / the Home drawer's
  "Continue listening" + "Recently viewed" banners ignored both
  `tap(label:)` and coordinate-based `tap(x:y:)`. The only
  navigation that worked was an incidental swipe that crossed a
  NavigationLink's frame. Workaround for sim-verification flows: do
  the navigation manually in the open simulator window before
  starting an automation pass, or accept that a TourDetail sanity
  check needs a human in the loop. Worth chasing if we want
  reliable end-to-end automation later.

- **`AtlasBottomModule.height` reads safe-area via UIWindowScene,
  not GeometryReader.** `ContentView` ignores the bottom safe area
  to host the floating island, which makes
  `GeometryReader.safeAreaInsets.bottom` return 0 everywhere it's
  reachable from. Looking up the active foreground scene's key
  window and reading its `safeAreaInsets.bottom` is the only path
  that gives the real ~34pt on Face-ID phones. Same trick HomeView
  already uses for `currentScreenHeight()` in the tours-in-view
  count math.

---

## What's left for V1

Unchanged from `HANDOFF-260524-3.md`:

- **A multi-stop walking tour** — the one M-qa item still gated
  by content. All 38 tours are single-stop. Once one multi-stop
  tour exists, the geofence + stop-advancement + manual-next
  checks can finally run on device.

- **Deferred design / polish pass** — theme tokens, real app icon,
  editorial copy, custom map pins (queued as PR #64 in another
  session), map controls (queued as PR #65 in another session).

- **TestFlight 1.0 (8) upload** — build number is bumped (PR #64,
  `57959bf`); owner archives from Xcode whenever ready. With PR
  #66 now merged this build would include the non-Home module
  geometry fix; if owner wants that on TestFlight, bump to
  1.0 (9) before archive.

---

## Tomorrow's queue

- If owner wants the module geometry fix on TestFlight before the
  next archive, bump `CURRENT_PROJECT_VERSION` 8 → 9 first
  (single-line PR, auto-merged on CI green per the new rule).
- Multi-stop tour content authoring is still the highest-leverage
  remaining V1 task — every M-qa step that's still open depends on
  it.
- PR #64 (map pin redesign) and PR #65 (map controls) are queued
  on other branches per the original PR #66 brief. They'll merge
  in cleanly assuming their own CI passes; conflicts are limited
  since this PR touched ContentView + tab/mini-player chrome
  and they're scoped to map content.
