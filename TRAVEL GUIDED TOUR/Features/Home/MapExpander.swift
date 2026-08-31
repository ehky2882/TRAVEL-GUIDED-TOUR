import CoreLocation
import MapKit
import SwiftUI

/// App-wide channel for the **expand** control on a detail page's inline map.
///
/// Owner, 2026-08-30: *"in the 'map' view i want to be able to click on a
/// button that 'expands' the map which effectively takes me back to the home
/// map view at the location of that particular item … with the placecard
/// showing, similar to if i were to get to a tour by searching."*
///
/// So expanding is not a bigger map — it is a **return to the one map**, framed
/// on what you were reading about. The inline maps on tour detail, a place, a
/// creator and a list are all previews; the Home map is where you pan, tap
/// neighbouring pins and carry on browsing. This is the door between them.
///
/// The landing itself is `PendingMapMove`, which Search already writes — so
/// arriving here looks exactly like arriving from a search result, deliberately.
///
/// 🔴 **`performExpand` is wired once by `ContentView`, and setting state alone
/// is NOT enough** — the same rule `TourPresenter.performDismiss` exists for.
/// Every surface with an expand button sits inside a UIKit slide-up layer that
/// completely covers the main window, and SwiftUI can stop delivering updates
/// to a covered hierarchy: an `.onChange` in `ContentView` may simply never
/// run, and the user gets a control that does nothing. The closure runs the
/// teardown directly instead.
@Observable
final class MapExpander {
    /// Performs the real work: tear every layer down, select Home, hand the
    /// move to `HomeSharedState`. Wired once by `ContentView`.
    @ObservationIgnored var performExpand: ((PendingMapMove) -> Void)?

    /// False only where nothing wired the closure — a preview, or a host that
    /// doesn't build the layers. Call sites hide the control rather than
    /// drawing one that cannot act.
    var isAvailable: Bool { performExpand != nil }

    /// Land on the Home map at `region`, optionally with a card already up.
    ///
    /// ⚠️ Pass the card's id here rather than setting it on `HomeSharedState`
    /// yourself: `HomeView.flyTo` opens by clearing any open card — correct for
    /// a fly-to, since a card left from the old location is stale at a new one
    /// — so a card set beforehand is wiped by the move itself.
    func expand(
        to region: MKCoordinateRegion,
        showingTour tourId: UUID? = nil,
        showingPlace placeId: UUID? = nil
    ) {
        performExpand?(
            PendingMapMove(
                region: region,
                placecardTourId: tourId,
                placecardPlaceId: placeId
            )
        )
    }

    /// Frame a whole set of tours, with no card.
    ///
    /// Owner decision 2026-08-30 for the creator and list pages: those maps
    /// hold many tours across many cities and have no single subject, so
    /// expanding them shows the lot — the same picture their own SHOW ALL
    /// control gives, on the map you can actually browse from. Raising one
    /// tour's card there would single out a tour arbitrarily.
    ///
    /// Returns without acting when there is nothing to frame, so a creator with
    /// no published tours yet gets a control that is hidden rather than inert
    /// (see `regionFraming`).
    func expand(framing tours: [Tour]) {
        guard let region = Self.regionFraming(tours) else { return }
        performExpand?(PendingMapMove(region: region))
    }

    /// The region covering every tour in `tours`, or nil when none can be
    /// placed on a map.
    ///
    /// ⚠️ Takes the pin coordinate — a single tour's only stop, or **stop 0**
    /// of a walk — not every stop and not the centroid, so this frames exactly
    /// what the Home map draws. A walk's centroid can sit hundreds of metres
    /// from any of its stops (Montreal's Downtown walk: 197 m), which is the
    /// bug session 102 fixed in the drawer.
    static func regionFraming(_ tours: [Tour]) -> MKCoordinateRegion? {
        let coordinates: [CLLocationCoordinate2D] = tours.compactMap { tour in
            HomeView.placecardCoordinate(for: tour)
        }
        return MapClustering.region(containing: coordinates)
    }
}
