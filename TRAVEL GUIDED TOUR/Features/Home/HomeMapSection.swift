import SwiftUI
import MapKit
import CoreLocation

/// Coordinate + view payload for the floating placecard preview the
/// map renders when a pin is tapped. Kept inert (no behavior, just
/// data) so `HomeMapSection` doesn't need to know how the placecard
/// is constructed.
struct PlacecardAnchor {
    let coordinate: CLLocationCoordinate2D
    let view: AnyView
}

/// Map section at the top of the home screen. Renders a pin per stop
/// across `tours`, centered on the user's location (or an NYC default
/// when location is denied / unavailable). Reports the visible
/// region's center after every pan so the parent can update the
/// "in view" count, and reports a tapped pin upward via
/// `onPinTapped` so the parent can pop up a placecard preview anchored
/// to that pin.
///
/// Pins are small filled circles in the Atlas accent color — no
/// category glyph, no balloon shape. At wide zoom (city-level) nearby
/// pins collapse into cluster badges; tapping a cluster zooms in to
/// break it apart.
///
/// When `placecard` is non-nil, the placecard view is rendered as
/// another map annotation anchored above the tapped pin so it tracks
/// the map's pan/zoom. Tapping the map outside any pin or the
/// placecard invokes `onMapTapped`, which the parent uses to dismiss
/// the placecard.
struct HomeMapSection: View {
    let tours: [Tour]
    /// Sites whose tours collapse into a single pin. Empty is the ordinary
    /// case for any catalog published before the place layer.
    let places: [Place]
    /// Markers prebuilt by `DataService`, passed only when NO filter is
    /// active — see `DataService.stopMarkers`. Building them is a full pass
    /// over the catalog, and this view used to do it on every render —
    /// including the one where a camera fly settles and re-clusters. Nil means
    /// "a filter is on, so the pins genuinely differ" and they are built
    /// here instead.
    var precomputedMarkers: [MapClustering.StopMarker]? = nil
    let userLocation: CLLocation?
    /// Device compass heading in degrees (0 = true north). When
    /// present, the user-location dot shows a directional wedge.
    let userHeading: CLLocationDirection?
    /// ID of the currently-selected pin (the one whose placecard is
    /// showing). Drives the StopPin's thicker selection ring. Pure
    /// presentation — pin taps go up via `onPinTapped`.
    let selectedTourId: UUID?
    /// Id of the currently-previewed place, so its pin can show the selected
    /// ring. Separate from `selectedTourId` because a place pin is not a tour.
    let selectedPlaceId: UUID?
    @Binding var cameraPosition: MapCameraPosition
    /// Active map type — Standard / Hybrid / Satellite. Lifted to the
    /// parent so the map-mode selector button can cycle it.
    let mapMode: MapMode
    /// Fires after a pan settles. The parent uses this to recompute
    /// the in-view tour count and any location-anchored UI.
    let onCameraChanged: (MKCoordinateRegion) -> Void
    /// Fires on every camera-change frame while the user is panning or
    /// flinging the map (`.continuous` frequency). The parent uses this
    /// to retract the drawer and fade the recenter button.
    let onCameraMoving: () -> Void
    /// Fires on every continuous camera frame with the live camera.
    /// The parent routes it into an isolated `@Observable` model read
    /// only by the leaf compass button, so the ~60/sec updates during
    /// a rotate gesture re-render just that small view — not all of
    /// `HomeView`. Carries the whole `MapCamera` (not just heading) so
    /// the parent can build a north-up reset camera from the current
    /// centre + distance. Replaces Apple's `MapCompass(scope:)`, whose
    /// external-placement scope binding renders a zero-size view on
    /// iOS 26 (verified — even forced visible it never paints).
    let onCameraInfoChanged: (MapCamera) -> Void
    /// Fires when the user taps a stop pin. Carries the tour id and
    /// the tapped stop's coordinate so the parent can anchor a
    /// placecard above that pin.
    let onPinTapped: (UUID, CLLocationCoordinate2D) -> Void
    /// Fires when the user taps a cluster that zooming cannot break
    /// apart — its members sit on the same coordinate, or the camera is
    /// already at building scale. Carries every tour in the cluster plus
    /// its anchor coordinate so the parent can stack one placecard per
    /// tour. Without this the tap is an infinite no-op and the tours
    /// underneath are unreachable from the map (see
    /// `MapClustering.canSeparateByZoom`).
    let onClusterTapped: ([UUID], CLLocationCoordinate2D) -> Void
    /// Fires when the user taps a pin standing for a **place** — a site several
    /// tours describe. Carries the place id and its coordinate.
    let onPlaceTapped: (UUID, CLLocationCoordinate2D) -> Void
    /// Fires when the user taps the map outside any pin or the
    /// placecard. Parent uses this to dismiss the placecard.
    let onMapTapped: () -> Void
    /// When non-nil, an annotation rendering `view` is anchored just
    /// above `coordinate` so it tracks the map as the user
    /// pans/zooms.
    let placecard: PlacecardAnchor?

    /// Current visible region, kept fresh by `.onMapCameraChange` so
    /// clustering math reacts to live pans and pinches.
    @State private var currentRegion: MKCoordinateRegion?

    var body: some View {
        styledMap
        // Map taps that don't hit an annotation propagate here —
        // SwiftUI prefers the inner annotation gestures, so pin and
        // placecard taps still fire. Parent uses this to dismiss the
        // placecard on tap-anywhere-else.
        .onTapGesture {
            onMapTapped()
        }
        // No MapCompass() here — the framework only renders it in the
        // fixed top-trailing slot (under the search bar + chips), and
        // its external-placement scope binding is broken on iOS 26.
        // `HomeView` draws its own compass button on the trailing edge
        // (opposite the recenter button), driven off `onCameraInfoChanged`.
        .mapControls {
            MapScaleView()
        }
        // `.continuous` fires on every animation frame during a
        // pan / pinch. We DON'T update `currentRegion` here —
        // re-bucketing 60× per second causes visible flicker as
        // SwiftUI tears down and re-adds annotations whose cluster
        // IDs shift. The only mid-gesture work is notifying the
        // parent to retract the drawer / cancel location tracking;
        // that closure is guard-gated so it only does work once
        // per gesture.
        .onMapCameraChange(frequency: .continuous) { context in
            onCameraMoving()
            onCameraInfoChanged(context.camera)
        }
        // `.onEnd` fires once when the gesture settles — that's
        // when we re-cluster. The annotations themselves are
        // positioned by lat/lon so they pan smoothly with the map
        // even while clusters are "frozen" from the prior region.
        .onMapCameraChange(frequency: .onEnd) { context in
            currentRegion = context.region
            onCameraChanged(context.region)
        }
        // Seed `currentRegion` from the initial camera position so
        // clusters appear on first render — `.onEnd` doesn't fire
        // until the user actually moves the map.
        .task {
            if currentRegion == nil {
                currentRegion = cameraPosition.region
            }
        }
    }

    /// Map view with the right SwiftUI `MapStyle` applied. Branched
    /// per `mapMode` because `mapStyle(_:)` takes a concrete
    /// `MapStyle` and `MapStyle` is a protocol — we can't smuggle
    /// the value through a stored property of protocol type.
    @ViewBuilder
    private var styledMap: some View {
        let map = Map(position: $cameraPosition) {
            ForEach(clusterItems, id: \.id) { item in
                Annotation(item.accessibilityLabel, coordinate: item.coordinate, anchor: .center) {
                    pinView(for: item)
                }
                .annotationTitles(.hidden)
            }

            if let userLocation {
                Annotation("My location", coordinate: userLocation.coordinate, anchor: .center) {
                    UserLocationDot(headingDegrees: wedgeRotationDegrees)
                }
                .annotationTitles(.hidden)
            }

            if let placecard {
                // `.bottom` anchors the view's bottom edge at the
                // pin's coordinate. The trailing `.padding(.bottom)`
                // lifts the placecard another ~14pt so it clears the
                // pin's circle instead of overlapping it.
                Annotation("Tour preview", coordinate: placecard.coordinate, anchor: .bottom) {
                    placecard.view
                        .padding(.bottom, 14)
                }
                .annotationTitles(.hidden)
            }
        }
        switch mapMode {
        // `.muted` emphasis desaturates the standard style so the
        // pins, placecard, and chrome don't compete with the map's
        // own colour. The POI include-list curates Apple's labels
        // down to the categories that matter to a tour-seeker
        // (cultural / civic / transit landmarks); the noise
        // (ATMs, gas stations, pharmacies, retail, etc.) is hidden
        // so the map reads as canvas, not a Yelp grid. Hybrid +
        // Imagery don't expose these options; they stay at default.
        case .standard: map.mapStyle(.standard(emphasis: .muted, pointsOfInterest: Self.tourPOI))
        case .hybrid:   map.mapStyle(.hybrid)
        case .imagery:  map.mapStyle(.imagery)
        }
    }

    // MARK: - Pin rendering

    /// Pins draw small (16–20pt circles) but hit-test at Apple's
    /// 44pt HIG minimum: the `.frame` + `.contentShape` below give
    /// every pin an invisible 44pt round tap area centered on the
    /// visual dot, without changing pin density on the map. Taps
    /// land on the gesture; drags still pass through to pan the map.
    @ViewBuilder
    private func pinView(for item: MapClustering.ClusterItem) -> some View {
        switch item.kind {
        case .single(let marker):
            if let placeId = marker.placeId {
                PlacePin(count: marker.placeTourCount, isSelected: placeId == selectedPlaceId)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPlaceTapped(placeId, marker.coordinate)
                    }
                    .accessibilityLabel("\(marker.title), \(marker.placeTourCount) tours")
                    .accessibilityAddTraits(.isButton)
            } else {
                StopPin(isSelected: marker.tourId == selectedTourId)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .onTapGesture {
                        onPinTapped(marker.tourId, marker.coordinate)
                    }
                    .accessibilityLabel(marker.title)
                    .accessibilityAddTraits(.isButton)
            }

        case .cluster(let count, let stops):
            ClusterPin(count: count)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .onTapGesture {
                    handleClusterTap(stops: stops, at: item.coordinate)
                }
                .accessibilityLabel("\(count) tours")
                .accessibilityAddTraits(.isButton)
        }
    }

    /// A cluster tap zooms in — unless zooming can't help, in which case
    /// the cluster goes up to the parent to be disambiguated as a stack
    /// of placecards.
    ///
    /// `MapClustering.needsDisambiguation` owns that judgement, so the
    /// home map and the maker map can't drift apart on when a tap stops
    /// being a zoom.
    private func handleClusterTap(stops: [MapClustering.StopMarker], at coordinate: CLLocationCoordinate2D) {
        if MapClustering.needsDisambiguation(stops: stops, currentSpan: currentRegion?.span) {
            onClusterTapped(stops.map(\.tourId), coordinate)
        } else {
            zoomIn(on: stops)
        }
    }

    // MARK: - Derived

    /// Screen-space rotation for the user-dot's heading wedge, in
    /// degrees — equal to the device compass heading so the wedge
    /// points the real-world direction the user is facing.
    /// `nil` hides the wedge when heading is unavailable.
    private var wedgeRotationDegrees: Double? {
        userHeading
    }

    /// The pins this map draws. Built by the shared `MapMarkers` so the home
    /// map and the maker page can't disagree about what a pin means: one pin
    /// per tour, except that tours sharing a place collapse into one pin for
    /// the place.
    private var allStopMarkers: [MapClustering.StopMarker] {
        precomputedMarkers ?? MapMarkers.markers(for: tours, places: places)
    }

    /// Bucket markers into the current visible region's grid, collapsing
    /// any cell that holds 2+ pins into a cluster. Grid resolution
    /// scales with `region.span`, so a city-wide view groups aggressively
    /// while a block-level view leaves everything individual.
    private var clusterItems: [MapClustering.ClusterItem] {
        MapClustering.cluster(markers: allStopMarkers, in: currentRegion)
    }

    /// Curated allowlist of Apple Maps POI categories — only the
    /// ones that help a tour-seeker get oriented (cultural, civic,
    /// nature, transit) survive. Categories like ATMs, gas stations,
    /// pharmacies, retail, restrooms, and laundry are filtered out
    /// so the map reads as a canvas for the Atlas pins rather than
    /// a Yelp grid. Easy to revisit; iterate by adding / removing
    /// categories here.
    ///
    /// Internal (not file-private) so `TourDetailView`'s inline
    /// preview map can apply the same allowlist — keeps the home
    /// map and the detail-sheet map visually consistent (same
    /// landmark-vs-business filter rules).
    static let tourPOI: PointOfInterestCategories = .including([
        // Cultural / civic landmarks
        .landmark, .museum, .nationalMonument, .library, .castle, .fortress,
        // Performance + venues
        .theater, .movieTheater, .musicVenue, .stadium,
        // Family / educational attractions
        .aquarium, .planetarium, .zoo, .amusementPark,
        // Nature + open space
        .park, .nationalPark, .beach, .marina,
        // Civic anchors
        .university,
        // Travel + transit
        .airport, .publicTransport, .hotel, .parking, .evCharger
    ])

    // The clustering pipeline — viewport cull, snapped span, absolute
    // grid bucketing — moved to `Components/MapClustering.swift` on
    // 2026-07-27 so the maker page's map could share it instead of
    // reimplementing it. Behaviour is unchanged; Home still uses the
    // default 20-cells-across density.

    /// Tighten the camera around a cluster's bounding box so it breaks
    /// apart on the next render. Mirrors MKMapView's default
    /// cluster-tap behavior. Passes the live span so the framing can
    /// never widen the camera (see `MapClustering.region(framing:within:)`).
    private func zoomIn(on stops: [MapClustering.StopMarker]) {
        guard let region = MapClustering.region(framing: stops, within: currentRegion?.span) else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(region)
        }
    }
}
