import SwiftUI

/// App-wide channel for presenting a maker page from outside the normal
/// navigation flow — specifically incoming deep links (a shared maker link).
///
/// Makers are normally *pushed* onto a local navigation stack (from a tour
/// detail, search result, etc.), so unlike tours there was no app-level way to
/// bring one up on demand. A deep link arrives at the App level with no stack
/// to push onto, so this presenter drives a `.sheet` in `ContentView`.
///
/// (Tours have the richer `TourPresenter` + UIKit bottom-layer slide-up; a
/// maker deep link is rare enough that a standard sheet is the right, low-risk
/// fit. A tour tapped inside the presented maker still slides up over it via
/// the bottom layer, which presents from the topmost view controller.)
@Observable
final class MakerPresenter {
    /// The maker to present as a sheet; nil means nothing is presented.
    var presentedMaker: Maker? = nil

    func present(_ maker: Maker) {
        presentedMaker = maker
    }

    func dismiss() {
        presentedMaker = nil
    }
}
