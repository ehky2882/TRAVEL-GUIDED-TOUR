import Foundation
import Observation

/// Drives the list bottom-layer in `ContentView`.
///
/// The twin of `TourPresenter`, `MakerPresenter` and `PlacePresenter`. A list
/// is a top-level screen — you arrive at one from Library, from a profile, or
/// from a shared link — and every top-level screen in this app slides up from
/// behind the bottom module. The list page was the last one still *pushing*
/// onto a nav stack, which is why it wore a back chevron while tour detail and
/// the place page wore an X (owner direction, 2026-08-20: the page should come
/// up from the bottom and close by sliding down).
@Observable
final class TourListPresenter {
    /// What is on screen — a named list or Liked. Both are the same screen
    /// (`TourListTarget`), so both arrive through this one presenter and get
    /// the same slide-up layer.
    var presented: TourListTarget? = nil

    /// Performs the real UIKit dismissal, wired once by `ContentView`.
    ///
    /// 🔴 **Setting the state above is NOT enough.** The slide-up and
    /// slide-down are driven by an `.onChange` in `ContentView`, which lives
    /// in the MAIN window — fully covered while a layer is up, and SwiftUI can
    /// stop delivering updates to a covered hierarchy. The state is written,
    /// the observer never runs, and the X does nothing. That is the dead tab
    /// bar of session 74 and the dead place pin of #532; `PlacePresenter`
    /// carries the same note for the same reason.
    @ObservationIgnored var performDismiss: (() -> Void)?

    func present(_ target: TourListTarget) {
        presented = target
    }

    /// Convenience for the common case: a named list whose row the caller
    /// already holds, so the title draws on the first frame.
    func present(listId: UUID, preloaded: TourList? = nil) {
        present(.list(id: listId, preloaded: preloaded))
    }

    func dismiss() {
        presented = nil
        performDismiss?()
    }
}
