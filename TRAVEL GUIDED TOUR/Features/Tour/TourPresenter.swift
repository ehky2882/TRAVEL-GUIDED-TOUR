import SwiftUI

/// App-wide channel for presenting `TourDetailView`. The actual
/// presentation is performed by `BottomLayerPresenter` (a UIKit
/// `UIPresentationController` bridged into SwiftUI) — this object
/// just holds the "what should be on screen right now" state.
///
/// Every entry point (drawer card, placecard, library row, search
/// result, rail carousel) calls `present(_:)` to bring the detail
/// up. The X close button on `TourDetailView` calls `dismiss()` to
/// take it back down. UIKit handles the slide animation, the
/// content lifecycle (presented view stays mounted until its
/// dismiss animation completes — no need for a "lag" mirror state
/// on this side), and touch pass-through to the mini-player + tab
/// bar.
@Observable
final class TourPresenter {
    /// The tour that should be visible. Set means "present"; nil
    /// means "dismiss". Drives `BottomLayerPresenter` in
    /// `ContentView`.
    var presentedTour: Tour? = nil

    func present(_ tour: Tour) {
        presentedTour = tour
    }

    func dismiss() {
        presentedTour = nil
    }
}
