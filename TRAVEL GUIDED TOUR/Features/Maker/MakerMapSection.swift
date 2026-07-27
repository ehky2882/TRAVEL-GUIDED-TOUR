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
/// direction 2026-07-27): a pannable map at `AtlasSpacing.heroHeight`
/// with square corners, living inside the page's scroll view. That
/// screen has shipped this arrangement for months, and its horizontal
/// inset is what makes it safe — the gutters either side of the map are
/// where a drag scrolls the page instead of panning the map. **The
/// caller applies that inset; this view must not fill the width.**
struct MakerMapSection: View {
    let tours: [Tour]
    let userLocation: CLLocation?
    /// Highlighted pin — thicker ring, larger dot.
    let selectedTourId: UUID?
    @Binding var cameraPosition: MapCameraPosition
    let onPinTapped: (UUID, CLLocationCoordinate2D) -> Void
    let onMapTapped: () -> Void

    /// Region the pins were last clustered against. Updated only when a
    /// gesture settles — see `HomeMapSection` for why re-bucketing
    /// mid-gesture flickers.
    @State private var currentRegion: MKCoordinateRegion?

    /// Cells across the visible region. Lower than the home map's 20
    /// because `cellsAcross` counts cells across the **region**, not the
    /// screen: at `heroHeight` the same 20 cells would span far fewer
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
        // Seed the region from the initial camera so pins cluster on the
        // very first render — `.onEnd` doesn't fire until the user moves
        // the map, and on this screen they may never move it at all.
        .task {
            if currentRegion == nil {
                currentRegion = cameraPosition.region
            }
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
            StopPin(isSelected: marker.tourId == selectedTourId)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .onTapGesture {
                    onPinTapped(marker.tourId, marker.coordinate)
                }
                .accessibilityLabel(marker.title)
                .accessibilityAddTraits(.isButton)

        case .cluster(let count, let stops):
            ClusterPin(count: count)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .onTapGesture {
                    zoomIn(on: stops)
                }
                .accessibilityLabel("\(count) tours")
                .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Derived

    /// One pin per tour. Multi-stop walks contribute only their entry
    /// stop (`order == 0`), so a six-stop walk doesn't scatter six pins
    /// across the city for what is one thing to open — same rule the
    /// home map uses.
    private var stopMarkers: [MapClustering.StopMarker] {
        tours.flatMap { tour in
            tour.stops
                .filter { tour.kind == .single || $0.order == 0 }
                .map { stop in
                    MapClustering.StopMarker(
                        id: stop.id,
                        tourId: tour.id,
                        title: stop.title,
                        coordinate: stop.coordinate
                    )
                }
        }
    }

    private var clusterItems: [MapClustering.ClusterItem] {
        MapClustering.cluster(
            markers: stopMarkers,
            in: currentRegion,
            cellsAcross: Self.cellsAcross
        )
    }

    private func zoomIn(on stops: [MapClustering.StopMarker]) {
        guard let region = MapClustering.region(framing: stops) else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(region)
        }
    }
}

// MARK: - Framing a maker's whole body of work

extension MakerMapSection {
    /// Region that frames every tour this maker has made.
    ///
    /// A maker working across continents gets a world-scale region, and
    /// that is the correct picture of them (owner direction 2026-07-27:
    /// "some users might have made tours all over the world, which will
    /// make the map very small, which is ok too"). Returns `nil` when
    /// there is nothing to frame, so the caller can hide the tab.
    static func initialRegion(for tours: [Tour]) -> MKCoordinateRegion? {
        let coordinates = tours.flatMap { tour in
            tour.stops
                .filter { tour.kind == .single || $0.order == 0 }
                .map(\.coordinate)
        }
        return MapClustering.region(containing: coordinates)
    }
}
