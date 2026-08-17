import SwiftUI
import CoreLocation
import MapKit

/// State shared between `HomeView`'s map surface (search bar, chips,
/// map control buttons, the map itself) and the home drawer — which
/// now lives at the `ContentView` level so it can render z-order ON
/// TOP of the mini-player + tab bar instead of behind them.
///
/// Both halves are siblings under `ContentView`'s ZStack; this object
/// is the only thing tying them together. It's instantiated in
/// `ContentView` and injected via `@Environment` so the two halves
/// stay in sync without prop-drilling.
@Observable
final class HomeSharedState {
    /// Active multi-select tag filter (owner decision D8). Empty = no
    /// tag filter. Chips combine per D6 (OR within a facet, AND across).
    /// The map filters its pin set on this; the drawer swaps its curated
    /// shelves for a flat results list while any filter is active.
    var selectedTags: Set<String> = []

    /// "Walks" format filter (§1.6) — narrows to multi-stop tours. A
    /// *format* filter (the tour's shape), distinct from the content-tag
    /// filters above, but it ANDs with them in the same chip row.
    var walksOnly: Bool = false

    /// True when any filter (tags or Walks) is active — the drawer reads
    /// this to decide shelves-vs-results and the header copy.
    var hasActiveFilters: Bool { !selectedTags.isEmpty || walksOnly }

    /// Tours behind the currently-tapped pin, plus the coordinate of
    /// that pin. Drives the placecard preview the map renders above it.
    ///
    /// A **list**, not one tour, because a pin can stand for more than
    /// one tour: when two tours share a coordinate exactly, no zoom can
    /// ever split them apart into separate pins, so tapping shows one
    /// placecard per tour stacked above the pin. Single-pin taps put
    /// exactly one tour here, which is the overwhelmingly common case.
    var placecardTours: [Tour] = []
    var placecardCoordinate: CLLocationCoordinate2D? = nil

    /// True while a placecard (single or stacked) is showing.
    var isShowingPlacecard: Bool { !placecardTours.isEmpty }

    /// The pin to draw with its selection ring — only when a single
    /// tour's own pin was tapped. A stack sits above a *cluster* pin,
    /// which has no selected state, so it deliberately selects nothing.
    var selectedPinTourId: UUID? {
        placecardTours.count == 1 ? placecardTours.first?.id : nil
    }

    /// Clear any open placecard. One edit point so every dismissal path
    /// (map tap, recenter, place-search fly-to) stays in step.
    func dismissPlacecard() {
        placecardTours = []
        placecardCoordinate = nil
    }

    /// The visible map region (set by the map's settled-camera
    /// callback). The drawer reads this to compute "N tours in view"
    /// in its header.
    var visibleRegion: MKCoordinateRegion? = nil

    /// In-flight bottom-sheet drag delta in points (negative = drag
    /// up, positive = drag down). The map control buttons read this
    /// so they stay glued to the drawer's top edge DURING the drag —
    /// not just after the snap.
    var sheetDragOffset: CGFloat = 0

    /// True while the map camera is mid-pan/-fling (between
    /// `.onMapCameraChange(.continuous)` and `.onMapCameraChange(.onEnd)`).
    /// The map writes it; the drawer reads it to render an animated
    /// *ELLIPSIS* in the "N tours in view" header while the count
    /// is still settling, instead of momentarily reading as "0 tours."
    var isMapMoving: Bool = false

    /// One-shot request to fly the map camera somewhere, set by
    /// `SearchView` when the user taps a place result and consumed +
    /// cleared by `HomeView`. Lets the Search screen drive the Home
    /// map without lifting `cameraPosition` out of `HomeView`.
    var pendingMapMove: PendingMapMove? = nil
}

/// A one-shot request to fly the Home map camera to a region. Written
/// by `SearchView` when the user taps a place result, consumed by
/// `HomeView` (which animates the camera there, then clears it).
///
/// Wrapped with a `UUID` so it's `Equatable` for `.onChange` even
/// though `MKCoordinateRegion` isn't — and so two flights to the *same*
/// region still register as distinct events worth re-flying to.
struct PendingMapMove: Equatable, Identifiable {
    let id = UUID()
    let region: MKCoordinateRegion

    static func == (lhs: PendingMapMove, rhs: PendingMapMove) -> Bool {
        lhs.id == rhs.id
    }
}
