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

    func present(_ maker: Maker) {
        presentedMaker = maker
    }

    func dismiss() {
        presentedMaker = nil
    }
}
