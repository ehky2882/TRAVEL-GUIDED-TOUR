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
@Observable
final class TourPresenter {
    /// The tour the user wants visible right now. Drives the layer's
    /// `.offset` modifier in `ContentView` — set means "slide up", nil
    /// means "slide down". State-set only; the animation lives on the
    /// layer itself, not in a `withAnimation` wrapper here.
    var presentedTour: Tour? = nil

    /// Mirrors `presentedTour` but LAGS during dismiss so the detail
    /// content stays rendered while the layer slides off-screen. Set
    /// **synchronously** inside `present(_:)` so the inner content is
    /// inserted on the SAME SwiftUI tick the layer's offset animation
    /// starts — otherwise the conditional `if let displayedTour` in
    /// `ContentView` inserts the content one tick later with SwiftUI's
    /// default opacity transition, which reads as a fade-in stacked on
    /// top of the slide (root cause of the open-from-drawer "fade in,
    /// fade out" report from session 5).
    ///
    /// `ContentView` also reads this to gate the drawer's `.zIndex`:
    /// when nil, drawer sits above mini-player + tab bar (PR #76's
    /// "last card visible at scroll-end" fix); when set, drawer drops
    /// below the detail layer so the slide covers it naturally. Held
    /// non-nil through the entire dismiss-slide so the drawer stays
    /// hidden behind the still-sliding detail; cleared 0.45s after
    /// `dismiss()` (just past the 0.4s slide).
    var displayedTour: Tour? = nil

    func present(_ tour: Tour) {
        presentedTour = tour
        displayedTour = tour
    }

    func dismiss() {
        presentedTour = nil
        // Hold `displayedTour` through the slide-down so the content
        // stays rendered while the layer slides off-screen. Slightly
        // longer than the 0.4s offset animation so the view is fully
        // off-screen before its content tears down.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.45))
            if presentedTour == nil {
                displayedTour = nil
            }
        }
    }
}
