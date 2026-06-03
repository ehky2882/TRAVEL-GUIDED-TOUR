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
    /// Active category-chip filter. The map filters its pin set on
    /// this; the drawer filters and sorts its tour list on it.
    var selectedCategory: TourCategory? = nil

    /// Currently-tapped tour + the coordinate of its tapped stop.
    /// Drives the placecard preview the map renders above the pin,
    /// and the matching drawer card's `isSelected` highlight.
    var placecardTour: Tour? = nil
    var placecardCoordinate: CLLocationCoordinate2D? = nil

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
}
