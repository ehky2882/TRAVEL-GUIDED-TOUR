# Atlas — Handoff Notes (2026-05-27, session 8)

UIKit-backed slide-up presentation for tour detail, plus a chrome
unification pass. Resumed mid-flight uncommitted work from a prior
abandoned session, fixed three regressions surfaced by visual
review, then pushed everything as one PR. TestFlight build cut.

---

## What shipped this session

### Core change: UIKit `UIPresentationController` for tour-detail slide

PR #76 / #77 / #78's SwiftUI `.offset` + `.transition` approach
was good enough but always fighting SwiftUI's animation system
for the right enter/exit shape. This session replaces that with
a UIKit `UIPresentationController` driving the slide. The
mini-player + tab bar are hoisted into a **secondary
higher-level `UIWindow`** (`PassThroughWindow`, `windowLevel =
.normal + 1`) so the modal in window 1 naturally slides up
*behind* them — same architecture Apple Music uses for its
persistent now-playing strip.

New files in `Components/`:

- **`BottomModuleWindow.swift`** — `AppSharedState` (`@Observable`
  carrying `selectedTab` + `showingFullPlayer` across the two
  windows) + `BottomModuleWindowController` that installs the
  `PassThroughWindow` on first appearance. `PassThroughWindow`
  overrides `hitTest`: hits inside the bottom-inset strip
  (`AtlasBottomModule.height()` = 126pt) are returned; hits
  above pass through to the main window.
- **`BottomModuleRoot.swift`** — SwiftUI root for window 2.
  VStack of `MiniPlayerBar` + `AtlasTabBar` pinned bottom; a
  full-width `secondaryBackground` Rectangle is painted behind
  them on every surface *except* Home root (so Home keeps the
  floating-island look with map showing through the 8pt sides
  + 8pt outer strip).
- **`BottomLayerPresentation.swift`** — `UIPresentationController`
  + slide-up/down animators (system spring, damping 1.0, 0.4s).
  Presented view's frame is full-screen so its bottom passes
  *behind* window 2 rather than stopping short.
  `BottomLayerContainerView` overrides hit testing so taps in
  the bottom strip pass through to window 2's mini-player + tab
  bar. `BottomLayerController` is the SwiftUI-facing public
  entry point; `ContentView.onChange(of: tourPresenter.presentedTour?.id)`
  calls `present` / `dismiss`.

App-level state shuffle: `TourPresenter` and the new
`AppSharedState` are promoted from `ContentView` to
`TRAVEL_GUIDED_TOURApp.swift` so window 2's host can read them
too. `TourPresenter` simplified — the `displayedTour` lag mirror
PR #77 needed for clean SwiftUI slide-in is unnecessary now
that UIKit owns the presented view's lifecycle.

### Bumps fixed this session

Three regressions surfaced during visual review of the
in-flight UIKit code:

1. **Library / Me tabs not switching.** Tapping the buttons
   updated the icon (`selectedTab = .library`) but the tab
   content didn't change. Root cause: `PassThroughWindow.hitTest`
   was rejecting any hit where `hit === rootViewController?.view`
   — but SwiftUI's `Button` hit-testing often returns the
   hosting view itself, not a deeper leaf. The check was
   silently passing those legitimate taps through to window 1,
   which has no tab bar. Fixed by dropping the identity check
   and relying purely on the geometric strip test.

2. **Detail open with new tab tapped → user appears stuck.**
   `appShared.selectedTab` updated, `ContentView`'s `tabContent`
   switched to `LibraryView`, but it stayed *behind* the detail
   modal so the user only saw the old detail's content with a
   different selected icon. Fixed with a new `.onChange(of:
   appShared.selectedTab)` in `ContentView` that calls
   `tourPresenter.dismiss()` when the tab changes while a tour
   is presented. Apple Music does the same.

3. **"Bump" hairline above the mini-player.** With the old
   `MiniPlayerBar.topGap = 8`, the painted bar's top edge sat
   8pt below the top of the mini-player view, so the
   transparent strip in window 2 showed window 1's chrome bg
   through it. Even when both are `secondarySystemBackground`
   the inter-window compositing wasn't pixel-perfect and read
   as a hairline. Owner-confirmed via diagnostic colours (body
   red, bar green, tab bar blue) that the seam is at the bar's
   top edge, not at the bar/tab-bar boundary. Set `topGap = 0`
   so the painted bar's top IS the top of the mini-player view
   — one window transition at one y instead of two.

### Detail view: action bar removed

Owner asked to drop the sticky action bar entirely (it was
going away in the upcoming design pass anyway). Start Tour /
bookmark / download buttons moved inline into the `ScrollView`
body after the stops list. Bottom inset is now a simple
`Color.clear.frame(height: AtlasBottomModule.height())` so the
last content line clears the mini-player + tab bar.

Other detail polish in this PR:

- `.toolbarBackground(.hidden, for: .navigationBar)` — SwiftUI
  was rendering `.toolbarBackground(Color, .visible)` as a
  *translucent material* tinted with the color, not a solid
  fill, so the nav bar always read as a slightly different
  shade than the body. Hidden so the hosting view's
  `.secondarySystemBackground` shows behind the X + title.
- `imageSection.padding(.top, AtlasSpacing.md)` — breathing
  room between the nav area and the hero image.
- `BottomLayerController` sets `hosting.view.backgroundColor =
  .secondarySystemBackground` + `hosting.traitOverrides.userInterfaceLevel
  = .elevated` so the detail body resolves the same elevated
  variant of `secondarySystemBackground` that window 2 does.
  (In dark mode UIKit's elevated variant is slightly lighter.)

### Tour content: hero image URLs → 1280px

The Wikimedia Commons hero photos were loading at the original
3840px source variant — ~9× larger than needed for ~400pt
iPhone width. Switched all 36 `heroImageURL`s in `Tours.json`
to the 1280px thumbnail variant. Validator green; tests pass.

---

## Known issue carried forward

**Subtle chrome shade mismatch in dark mode.** Owner reports
the detail body still reads as a *very subtly* different shade
than the mini-player + tab bar even with the
`.userInterfaceLevel = .elevated` override on the detail's
hosting controller. The override narrows the gap but doesn't
fully close it. Saw the same effect when the body was set to
red for diagnosis — the seam was geometrically at the bar's top
edge.

Leads for next session:

1. **Pure RGB instead of system semantic.** Replace
   `Color(uiColor: .secondarySystemBackground)` in
   `AtlasColors` with a hardcoded `Color(red: 28/255, green:
   28/255, blue: 30/255)` (dark) / `(242, 242, 247)` (light).
   System semantic colors are subtle to control across windows /
   elevation contexts; a fixed RGB removes ambiguity.

2. **Eliminate the two-window boundary.** Make window 2 paint
   *no* `secondaryBackground` at all (no `.background` on
   `MiniPlayerBar` / `AtlasTabBar`); have window 1 paint the
   entire bottom region. Then there's no inter-window
   compositing transition for the eye to catch. Floating-island
   on Home would need a different mechanism (`ContentView`'s
   conditional Rectangle, with side insets + bottom outer
   strip preserved).

3. **Try the same `.elevated` trait override on window 2's
   hosting controller too.** If window 2 is at `.base` by
   default and the detail is forced to `.elevated`, the
   *mini-player* might be the one at base and the *detail* at
   elevated — opposite of what we assumed. Flipping the
   override might match them.

---

## Verification

- `swift scripts/validate-tours.swift`: 38 tours, 2 makers, 0
  errors (Tours.json hero URL changes structural-equivalent).
- `test_sim`: 84/84 passing.
- `build_run_sim`: clean.
- Visual verification in iPhone 17 Pro simulator: Home
  floating-island confirmed; Library / Me / Detail edge-to-edge
  confirmed; tab switching with + without detail presented
  confirmed; subtle chrome shade gap remains.

---

## TestFlight

- Build **1.0 (12)** — `CURRENT_PROJECT_VERSION` bumped from
  11 → 12. `xcodebuild archive` run cleanly; owner picks up
  from Organizer → Distribute App → Upload.

---

## Files touched this session

- **New:** `TRAVEL GUIDED TOUR/Components/BottomLayerPresentation.swift`
  (~290 lines).
- **New:** `TRAVEL GUIDED TOUR/Components/BottomModuleRoot.swift`
  (~60 lines).
- **New:** `TRAVEL GUIDED TOUR/Components/BottomModuleWindow.swift`
  (~125 lines).
- **Rewritten:** `TRAVEL GUIDED TOUR/ContentView.swift` — tour
  detail is now driven by `BottomLayerController` via
  `.onChange`, drawer-only Home overlay, tap-tab dismisses
  detail.
- **Modified:** `TRAVEL GUIDED TOUR/TRAVEL_GUIDED_TOURApp.swift`
  — installs the secondary window on `.onAppear`.
- **Modified:** `TRAVEL GUIDED TOUR/Features/Tour/TourPresenter.swift`
  — dropped `displayedTour` lag mirror.
- **Modified:** `TRAVEL GUIDED TOUR/Features/Tour/TourDetailView.swift`
  — action bar removed, buttons inline, toolbar bg hidden,
  image top padding.
- **Modified:** `TRAVEL GUIDED TOUR/Features/Player/MiniPlayerBar.swift`
  — `topGap = 0`.
- **Modified:** `TRAVEL GUIDED TOUR/Resources/Tours.json` — 36
  hero image URLs switched to 1280px thumbs.
- **Modified:** `CLAUDE.md` — Current State leads with session 8.
- **Modified:** `archive/README.md` — entry for this handoff.
- **Modified:** `TRAVEL GUIDED TOUR.xcodeproj/project.pbxproj`
  — `CURRENT_PROJECT_VERSION` 11 → 12.
