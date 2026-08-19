import CoreLocation
import MapKit
import SwiftUI

/// The MAP tab on a maker page — where in the world this maker's tours are.
///
/// Deliberately thin next to `HomeMapSection`. That view carries twelve
/// parameters, most of which exist to serve things this screen doesn't
/// have: the home drawer's retraction, the compass button, the map-mode
/// picker, the scale overlay. Rather than inherit all of it, this takes
/// the six inputs a maker map actually needs and shares the parts that
/// matter — `MapClustering` and `MapPins` — so pin styling and cluster
/// behaviour can't drift between the two maps.
///
/// **Treatment copied from `TourDetailView.mapContent`** (owner
/// direction 2026-07-27): a pannable map at the shared hero ratio
/// with square corners, living inside the page's scroll view. That
/// screen has shipped this arrangement for months, and its horizontal
/// inset is what makes it safe — the gutters either side of the map are
/// where a drag scrolls the page instead of panning the map. **The
/// caller applies that inset; this view must not fill the width.**
struct MakerMapSection: View {
    let tours: [Tour]
    /// Sites whose tours collapse into a single pin — passed through so this
    /// map and the home map draw the same thing for the same catalog.
    let places: [Place]
    let userLocation: CLLocation?
    /// Highlighted pin — thicker ring, larger dot.
    let selectedTourId: UUID?
    @Binding var cameraPosition: MapCameraPosition
    /// Where to open. Framed to fit every tour this maker has made — see
    /// `initialRegion(for:)`, which falls back to a world view when there
    /// is nothing to frame. Applied to both the camera *and* the
    /// clustering region on first appear; see the `.task` below for why
    /// those must happen together.
    let initialRegion: MKCoordinateRegion
    let onPinTapped: (UUID, CLLocationCoordinate2D) -> Void
    /// Fires when a pin standing for a place is tapped.
    let onPlaceTapped: (UUID, CLLocationCoordinate2D) -> Void
    /// Fires when a tapped cluster can't be broken apart by zooming —
    /// its members share a coordinate, or the camera is already at
    /// building scale. Carries every tour under the pin so the parent can
    /// stack a place card per tour, the same answer the home map gives.
    /// Without it the tap is a dead end and those tours are unreachable
    /// from this map (see `MapClustering.needsDisambiguation`).
    let onClusterTapped: ([UUID], CLLocationCoordinate2D) -> Void
    let onMapTapped: () -> Void
    /// When non-nil, rendered as an annotation anchored above
    /// `coordinate` so it tracks the map. The parent decides what goes in
    /// it; this view stays unaware of the concrete place-card type, just
    /// as `HomeMapSection` does.
    let placecard: PlacecardAnchor?

    /// Region the pins were last clustered against. Updated only when a
    /// gesture settles — see `HomeMapSection` for why re-bucketing
    /// mid-gesture flickers.
    @State private var currentRegion: MKCoordinateRegion?

    /// Cells across the visible region. Lower than the home map's 20
    /// because `cellsAcross` counts cells across the **region**, not the
    /// screen: in a hero-sized frame the same 20 cells would span far fewer
    /// points, so visually adjacent pins would refuse to merge.
    private static let cellsAcross: Double = 12

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(clusterItems, id: \.id) { item in
                Annotation(item.accessibilityLabel, coordinate: item.coordinate, anchor: .center) {
                    pinView(for: item)
                }
                .annotationTitles(.hidden)
            }

            if let userLocation {
                Annotation("My location", coordinate: userLocation.coordinate, anchor: .center) {
                    // No heading wedge: this map has no compass and the
                    // user isn't navigating from it.
                    UserLocationDot(headingDegrees: nil)
                }
                .annotationTitles(.hidden)
            }

            if let placecard {
                // `.bottom` puts the stack's bottom edge on the pin's
                // coordinate; the padding lifts it clear of the pin
                // itself. Identical treatment to the home map.
                Annotation("Tour preview", coordinate: placecard.coordinate, anchor: .bottom) {
                    placecard.view
                        .padding(.bottom, 14)
                }
                .annotationTitles(.hidden)
            }
        }
        // Same canvas as the home map and the tour-detail preview:
        // muted standard emphasis plus the shared POI allowlist, so
        // landmarks and transit show through but ATMs and retail don't.
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: HomeMapSection.tourPOI))
        // No `.mapControls` — the scale overlay wants more vertical room
        // than this frame has.
        .onTapGesture { onMapTapped() }
        // Re-cluster only when the gesture settles. Annotations are
        // positioned by lat/lon, so they pan smoothly with the map even
        // while clusters stay frozen from the prior region.
        .onMapCameraChange(frequency: .onEnd) { context in
            currentRegion = context.region
        }
        // Frame the map AND seed the clustering region together, in one
        // place, on first appear.
        //
        // ⚠️ These must happen together. `currentRegion` is what
        // clustering buckets against, and `.onEnd` doesn't fire until
        // the user moves the map — which on this screen they may never
        // do. An earlier version had the parent set the camera in its
        // own `.task` while this view seeded `currentRegion` from
        // `cameraPosition.region` in another: whichever ran first, the
        // camera was still `.automatic` (region `nil`) when the seed
        // read it, so `currentRegion` stayed nil and every pin rendered
        // unclustered until the first pan. A maker with 40 tours in one
        // city would open to a pile of overlapping dots.
        .task {
            guard currentRegion == nil else { return }
            cameraPosition = .region(initialRegion)
            currentRegion = initialRegion
        }
    }

    // MARK: - Pins

    /// Pins draw at 16–20pt but hit-test at Apple's 44pt HIG minimum —
    /// the invisible `.frame` + `.contentShape` do that without changing
    /// pin density. Taps land on the gesture; drags still pan the map.
    @ViewBuilder
    private func pinView(for item: MapClustering.ClusterItem) -> some View {
        switch item.kind {
        case .single(let marker):
            if let placeId = marker.placeId {
                PlacePin(count: marker.placeTourCount)
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
                    if MapClustering.needsDisambiguation(stops: stops, currentSpan: currentRegion?.span) {
                        onClusterTapped(stops.map(\.tourId), item.coordinate)
                    } else {
                        zoomIn(on: stops)
                    }
                }
                .accessibilityLabel("\(count) tours")
                .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Derived

    /// The pins this map draws, from the shared builder — one per tour, except
    /// that tours sharing a place collapse into one pin for the place. Using
    /// the same builder as the home map is what stops the two screens showing
    /// a different number of pins for the same catalog.
    private var stopMarkers: [MapClustering.StopMarker] {
        MapMarkers.markers(for: tours, places: places)
    }

    private var clusterItems: [MapClustering.ClusterItem] {
        MapClustering.cluster(
            markers: stopMarkers,
            in: currentRegion,
            cellsAcross: Self.cellsAcross
        )
    }

    /// Passing the live span keeps a cluster tap from ever *widening*
    /// the camera — the framing helper floors its span at ~1.1 km, but
    /// clusters form well below that, so without this a tap on a tight
    /// cluster zoomed out and re-rendered the same pin.
    ///
    /// Only ordinary clusters reach here — ones zooming can actually
    /// break apart. The rest go up via `onClusterTapped`.
    private func zoomIn(on stops: [MapClustering.StopMarker]) {
        guard let region = MapClustering.region(framing: stops, within: currentRegion?.span) else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(region)
        }
    }
}

// MARK: - Framing a maker's whole body of work

extension MakerMapSection {
    /// The whole world, centred on the Atlantic — what a maker with no
    /// tours yet opens to (owner direction 2026-07-27: "if a user doesn't
    /// have any tours, we should still show a map… zoomed out as far as
    /// possible, centered on atlantic ocean").
    ///
    /// The Atlantic centre is what puts the Americas, Europe and Africa on
    /// screen at once, so the map reads as *the world* rather than as one
    /// continent someone forgot to move away from. The span is deliberately
    /// past what Mercator can draw; MapKit clamps it to fully zoomed out.
    static let worldRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: -30),
        span: MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 360)
    )

    /// Region that frames every tour this maker has made.
    ///
    /// A maker working across continents gets a world-scale region, and
    /// that is the correct picture of them (owner direction 2026-07-27:
    /// "some users might have made tours all over the world, which will
    /// make the map very small, which is ok too"). A maker with nothing
    /// yet gets `worldRegion` — the tab still shows a real, pannable map
    /// rather than a grey box.
    static func initialRegion(for tours: [Tour]) -> MKCoordinateRegion {
        let coordinates = tours.flatMap { tour in
            tour.stops
                .filter { tour.kind == .single || $0.order == 0 }
                .map(\.coordinate)
        }
        return MapClustering.region(containing: coordinates) ?? worldRegion
    }
}
