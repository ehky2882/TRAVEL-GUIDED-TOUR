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

    /// Performs the real UIKit dismissal, wired once by `ContentView`.
    ///
    /// 🔴 **Setting the state above is NOT enough, and this is why.** The
    /// slide-up and slide-down are performed by an `.onChange` in
    /// `ContentView` — which lives in the MAIN window. While a layer is up
    /// that window is fully covered by a UIKit modal, and SwiftUI can stop
    /// delivering updates to a covered hierarchy: the state is written and
    /// the observer never runs. The user sees a control that does nothing.
    ///
    /// That is what made the X on tour detail and the bottom tab bar both
    /// stop working once you had been into a creator page and back — the taps
    /// fired, the state cleared, and nothing came down. Same root cause as the
    /// dead place pin (#532) and the dead tab bar of session 74:
    /// **never put a side effect that must run in a window a modal can cover.**
    ///
    /// Calling this makes dismissal independent of that observer. The
    /// `.onChange` remains as a backstop and is idempotent — the controller
    /// no-ops when nothing is presented.
    @ObservationIgnored var performDismiss: (() -> Void)?

    func present(_ tour: Tour) {
        presentedTour = tour
    }

    func dismiss() {
        presentedTour = nil
        performDismiss?()
    }
}
