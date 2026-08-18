import Foundation
import Observation

/// Drives the place bottom-layer in `ContentView`.
///
/// The exact twin of `TourPresenter` and `MakerPresenter`, deliberately: a
/// place is a top-level screen reached from a map pin, and every top-level
/// screen in this app slides up from behind the bottom module rather than
/// pushing onto a nav stack. Inventing a sheet here would have made the place
/// page the one screen that behaves differently.
@Observable
final class PlacePresenter {
    /// The place to present; nil means nothing is presented.
    var presentedPlace: Place? = nil

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

    func present(_ place: Place) {
        presentedPlace = place
    }

    func dismiss() {
        presentedPlace = nil
        performDismiss?()
    }
}
