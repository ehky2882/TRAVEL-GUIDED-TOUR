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

    func present(_ place: Place) {
        presentedPlace = place
    }

    func dismiss() {
        presentedPlace = nil
    }
}
