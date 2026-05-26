import SwiftUI

/// App-wide channel for presenting `TourDetailView`. Owned by
/// `ContentView`, which renders the detail as a slide-up LAYER in
/// its `ZStack` (NOT a system `.sheet`, which would modally cover
/// the mini-player + tab bar — the owner wants those visible at all
/// times, swapped to their full-edge geometry via `navState.push()`).
///
/// Every entry point (drawer card, placecard, library card, search
/// result, rail carousel) calls `present(tour:)` to slide the detail
/// up. The X close button on `TourDetailView` calls `dismiss()` to
/// slide it back down.
///
/// **⚠️ OPEN ISSUE — slide animation, owner-flagged, tracked in PR
/// #77.** The current `.offset` + `.animation(_, value:)` approach
/// in `ContentView` does not feel right to the owner — present from
/// the drawer reads as a fade, dismiss reads as a fade. Multiple
/// approaches tried in session 5 of 2026-05-25; see the **Open
/// issue** section in `CLAUDE.md` for the full log of leads.
/// **Do not iterate on this in the bulk PR** — the animation fix is
/// owned by the follow-up.
@Observable
final class TourPresenter {
    var presentedTour: Tour? = nil

    /// State-set only — the actual slide-up / slide-down animation
    /// lives on the layer's `.animation(.smooth(0.4), value:)`
    /// modifier in `ContentView`. Wrapping these in `withAnimation`
    /// here would interfere with that modifier and cause SwiftUI to
    /// fall back to default removal transitions (which read as a
    /// fade-out rather than a slide-down on this view tree).
    func present(_ tour: Tour) {
        presentedTour = tour
    }

    func dismiss() {
        presentedTour = nil
    }
}
