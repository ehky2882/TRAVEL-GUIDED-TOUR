import SwiftUI

/// App-wide channel for presenting a public maker page as its **own
/// top-level screen** — the maker twin of `TourPresenter`.
///
/// `ContentView` drives a UIKit bottom-layer slide-up off `presentedMaker`
/// (the same treatment tours get), so a creator page opens consistently from
/// anywhere, **including with no navigation context**: an incoming deep link
/// (a shared maker link, even on cold launch), a Search result, or a
/// saved-maker row. `MakerView(mode: .publicStandalone)` shows an X close
/// wired to `dismiss()`.
///
/// The contextual "Go to creator" from a tour / the player deliberately stays
/// an in-stack push (back returns to the tour) rather than routing here.
@Observable
final class MakerPresenter {
    /// The maker to present; nil means nothing is presented. Drives the
    /// maker bottom-layer in `ContentView`.
    var presentedMaker: Maker? = nil

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

    func present(_ maker: Maker) {
        presentedMaker = maker
    }

    func dismiss() {
        presentedMaker = nil
        performDismiss?()
    }
}
