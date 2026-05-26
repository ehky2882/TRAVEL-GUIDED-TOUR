# Open issue: tour-detail slide animation

**Status:** open — owner-flagged 2026-05-25 session 5. Bulk refactor
landed in PR #76. This PR (#77) is a tracking stub for the fix.

## What's broken

After PR #76 made `TourDetailView` slide up as a layer in the
`ContentView` ZStack (instead of pushing via `NavigationLink`), the
present + dismiss animations don't feel right.

Owner's verbatim feedback (in order):

> "the animation of sliding up and x close (slide down) needs a lot
> of refinement. very clunky."

> "no good. it should feel like a full sheet (edge to edge) coming
> up and full sheet going down"

> "full screen done but the slide animation still not feeling clean.
> on exit, still fading out."

> "from the drawer - there is hardly animation. fade in, fade out.
> from the placecard, fade in, slide down out. so not even the same."

> "this is not working. issue is not getting fixed. make note of
> this issue in the main and issue a new pr just for this."

## Important clue

**Behavior differs by entry point.** From the home drawer the user
sees fade-both-ways. From the placecard the user sees fade-in /
slide-down-out. This is the strongest signal in the failure log —
something in the drawer's transition is overshadowing the detail's
slide, since both entry points call the same `TourPresenter.present`.

## Fix attempts (all in session 5, none accepted)

| # | Approach | Outcome |
|---|----------|---------|
| 1 | `.sheet(item:)` (system modal) | Covers mini-player + tab bar — owner rejected. |
| 2 | Custom layer in ZStack with `.transition(.move(edge: .bottom))` + `.clipShape` + `.shadow` + `withAnimation(.smooth)` | Slide-up works; dismiss reads as fade. |
| 3 | Strip `clipShape` + `shadow`, add background extending top safe area | Slide-up covers full screen now; dismiss still fades. |
| 4 | ZStack-wrap layer to give it single SwiftUI identity, always-render drawer with opacity | Dismiss still fades from owner's perspective. |
| 5 | Switch from `.transition` to explicit `.offset` + `.animation(_, value:)` with lagging `displayedTour` for content lifecycle | Owner: drawer-case → fade both ways; placecard-case → fade in / slide-down out. Different behavior per entry point. |
| 6 | Cap off-screen offset to actual screen height (was 2000), animate drawer opacity on the same 0.4s clock | Still not satisfactory per owner. Session ended here. |

## Current code (after PR #76 lands)

- `ContentView.body` always renders the detail layer (no `if let`
  conditional on the layer's existence).
- Layer position controlled by `.offset(y: presentedTour == nil ?
  screenHeight : 0)`. `screenHeight` is looked up via
  `UIWindowScene.screen.bounds.height` so the off-screen state is
  exactly one screen below.
- Animation: `.animation(.smooth(duration: 0.4), value:
  tourPresenter.presentedTour != nil)`.
- `displayedTour` (`@State` on `ContentView`) lags `presentedTour`
  on dismiss by 0.45s via `Task.sleep` in `.onChange` so the inner
  content stays rendered through the slide-down.
- Drawer opacity also animates on the same `.smooth(0.4)` curve.
- `TourPresenter.present` / `dismiss` are plain assignments — no
  `withAnimation` wrapper (it was found to fight the layer's
  `.animation(_, value:)` modifier).

## Best leads for the fix

1. **Move `displayedTour` ownership onto `TourPresenter` and update
   it synchronously inside `present(_:)` / `dismiss()`.** Today it's
   on `ContentView` and updated via `.onChange`, which fires AFTER
   the offset animation starts — the inner `if let tour =
   displayedTour` may flicker content in/out during the slide.
2. **Capture an actual video of the running animation.** Owner's
   "fade vs slide" distinction per entry point is the strongest
   clue. Run the simulator, screen-record present/dismiss from both
   the drawer and the placecard, scrub frame-by-frame to see what
   the offset is actually doing vs. what the user perceives.
3. **Hold the drawer at full opacity through the slide-up.** When
   opened FROM the drawer, the drawer is the dominant visible
   element pre-tap. Its `.opacity` change alongside the detail's
   offset may overshadow the slide entirely. Try a delayed-fade so
   the drawer stays visible UNTIL the detail is fully up, then
   fades.
4. **Try `.matchedGeometryEffect`** between the tapped card and the
   detail layer's first frame. Apple Maps' tap-pin → card-expand
   uses this pattern. The slide would be a true geometric morph
   rather than a free-standing layer slide.
5. **Nuclear option:** `UIViewControllerRepresentable` bridging a
   custom UIKit presentation that mimics the system sheet but
   exposes a configurable bottom inset (so the mini-player + tab
   bar remain visible). Loses the SwiftUI-idiomatic feel but gets
   pixel-perfect iOS sheet motion. Worth doing only if 1–4 all fail.

## Done when

Owner can open + close the detail from EVERY entry point (drawer
card, drawer quick-resume banner, placecard, library row, search
result, rail card, maker tour row) and sees a clean slide both ways
that reads as a "full sheet" motion. No fade, no per-entry-point
difference.
