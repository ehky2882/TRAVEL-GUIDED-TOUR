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
    let userLocation: CLLocation?
    /// Device compass heading in degrees (0 = true north). When
    /// present, the user-location dot shows a directional wedge.
    let userHeading: CLLocationDirection?
    /// ID of the currently-selected pin (the one whose placecard is
    /// showing). Drives the StopPin's thicker selection ring. Pure
    /// presentation — pin taps go up via `onPinTapped`.
    let selectedTourId: UUID?
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
    /// Fires when the user taps a stop pin. Carries the tour id and
    /// the tapped stop's coordinate so the parent can anchor a
    /// placecard above that pin.
    let onPinTapped: (UUID, CLLocationCoordinate2D) -> Void
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
        .mapControls {
            MapCompass()
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
        .onMapCameraChange(frequency: .continuous) { _ in
            onCameraMoving()
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
        case .standard: map.mapStyle(.standard)
        case .hybrid:   map.mapStyle(.hybrid)
        case .imagery:  map.mapStyle(.imagery)
        }
    }

    // MARK: - Pin rendering

    @ViewBuilder
    private func pinView(for item: ClusterItem) -> some View {
        switch item.kind {
        case .single(let marker):
            StopPin(isSelected: marker.tourId == selectedTourId)
                .onTapGesture {
                    onPinTapped(marker.tourId, marker.coordinate)
                }
                .accessibilityLabel(marker.title)
                .accessibilityAddTraits(.isButton)

        case .cluster(let count, let stops):
            ClusterPin(count: count)
                .onTapGesture {
                    zoomIn(on: stops)
                }
                .accessibilityLabel("\(count) tours")
                .accessibilityAddTraits(.isButton)
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

    /// All stops across every tour, flattened into pin descriptors.
    private var allStopMarkers: [StopMarker] {
        tours.flatMap { tour in
            tour.stops.map { stop in
                StopMarker(
                    id: stop.id,
                    tourId: tour.id,
                    title: stop.title,
                    coordinate: stop.coordinate
                )
            }
        }
    }

    /// Bucket markers into the current visible region's grid, collapsing
    /// any cell that holds 2+ pins into a cluster. Grid resolution
    /// scales with `region.span`, so a city-wide view groups aggressively
    /// while a block-level view leaves everything individual.
    private var clusterItems: [ClusterItem] {
        Self.cluster(markers: allStopMarkers, in: currentRegion)
    }

    private static func cluster(markers: [StopMarker], in region: MKCoordinateRegion?) -> [ClusterItem] {
        guard let region else {
            return markers.map { ClusterItem(coordinate: $0.coordinate, kind: .single($0)) }
        }

        // 14 cells across the visible region. Empirically this gives
        // ~50–80pt cell pitch at typical iPhone sizes — close enough
        // that dense Manhattan clumps merge but Brooklyn/NJ outliers
        // stay separate.
        let cellsAcross: Double = 14
        let cellSpanLat = region.span.latitudeDelta / cellsAcross
        let cellSpanLon = region.span.longitudeDelta / cellsAcross
        guard cellSpanLat > 0, cellSpanLon > 0 else {
            return markers.map { ClusterItem(coordinate: $0.coordinate, kind: .single($0)) }
        }

        // Bucket by an ABSOLUTE (lat=0, lon=0) grid origin rather
        // than the visible region's southwest corner. With a
        // region-relative origin every pan would re-index every
        // pin (the origin shifts with the camera), so a marker's
        // bucket key — and therefore its cluster's SwiftUI
        // annotation ID — would change on every recompute. With
        // an absolute origin the bucket assignment depends only
        // on the marker's coordinate and the current zoom level
        // (cell pitch), so a pan with no zoom change keeps every
        // cluster's ID stable across recomputes: SwiftUI updates
        // the existing annotation in place instead of removing +
        // re-adding it.
        var buckets: [BucketKey: [StopMarker]] = [:]
        for marker in markers {
            let row = Int(floor(marker.coordinate.latitude / cellSpanLat))
            let col = Int(floor(marker.coordinate.longitude / cellSpanLon))
            buckets[BucketKey(row: row, col: col), default: []].append(marker)
        }

        return buckets.map { key, stops in
            if stops.count == 1, let only = stops.first {
                return ClusterItem(coordinate: only.coordinate, kind: .single(only))
            }
            let avgLat = stops.reduce(0) { $0 + $1.coordinate.latitude } / Double(stops.count)
            let avgLon = stops.reduce(0) { $0 + $1.coordinate.longitude } / Double(stops.count)
            return ClusterItem(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                kind: .cluster(count: stops.count, stops: stops),
                bucketKey: key
            )
        }
    }

    /// Tighten the camera around a cluster's bounding box so it breaks
    /// apart on the next render. Mirrors MKMapView's default
    /// cluster-tap behavior.
    private func zoomIn(on stops: [StopMarker]) {
        guard !stops.isEmpty else { return }
        let lats = stops.map(\.coordinate.latitude)
        let lons = stops.map(\.coordinate.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        // Pad by 2.5x so the cluster doesn't hug the edges, and floor
        // at a span that's roughly neighborhood-level — keeps a single
        // tap from over-zooming into a 1-block view.
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 2.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 2.5, 0.01)
        )
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}

// MARK: - Pin views

/// Small filled circle, accent-tinted. Selected state thickens the
/// ring and bumps the radius so the active pin pops above its
/// neighbors without changing pin density elsewhere.
private struct StopPin: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(AtlasColors.accent)
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle().stroke(Color.white, lineWidth: isSelected ? 3 : 1.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
            .contentShape(Circle())
    }

    private var diameter: CGFloat { isSelected ? 18 : 14 }
}

/// Cluster badge: a larger circle with a count, in the accent color
/// so it reads as the same family as the individual pins.
private struct ClusterPin: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(AtlasColors.accent.opacity(0.25))
                .frame(width: outerDiameter, height: outerDiameter)
            Circle()
                .fill(AtlasColors.accent)
                .frame(width: innerDiameter, height: innerDiameter)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
        .contentShape(Circle())
    }

    private var innerDiameter: CGFloat {
        switch count {
        case ..<10: return 26
        case ..<100: return 30
        default: return 34
        }
    }

    private var outerDiameter: CGFloat { innerDiameter + 10 }
}

// MARK: - Cluster model

private struct StopMarker: Identifiable, Hashable {
    let id: UUID
    let tourId: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: StopMarker, rhs: StopMarker) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

private struct BucketKey: Hashable {
    let row: Int
    let col: Int
}

private struct ClusterItem: Identifiable {
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    private let bucketKey: BucketKey?

    init(coordinate: CLLocationCoordinate2D, kind: Kind, bucketKey: BucketKey? = nil) {
        self.coordinate = coordinate
        self.kind = kind
        self.bucketKey = bucketKey
    }

    enum Kind {
        case single(StopMarker)
        case cluster(count: Int, stops: [StopMarker])
    }

    var id: String {
        switch kind {
        case .single(let m): return "s-\(m.id.uuidString)"
        case .cluster(let count, _):
            let key = bucketKey.map { "\($0.row),\($0.col)" } ?? "n"
            return "c-\(key)-\(count)"
        }
    }

    var accessibilityLabel: String {
        switch kind {
        case .single(let m): return m.title
        case .cluster(let count, _): return "\(count) tours"
        }
    }
}

/// iOS-Maps-style user-location indicator: a soft accuracy halo, an
/// optional directional wedge showing which way the device is
/// facing, and the blue dot itself. All colors are explicit (not
/// `.tint`-derived) so the dot stays Apple-Maps blue rather than
/// inheriting the terracotta app accent.
private struct UserLocationDot: View {
    /// Screen-space rotation for the heading wedge, in degrees
    /// (0 = pointing up). `nil` hides the wedge.
    let headingDegrees: Double?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 46, height: 46)

            if let headingDegrees {
                HeadingWedge()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.55), Color.blue.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 34, height: 26)
                    .offset(y: -16)
                    .rotationEffect(.degrees(headingDegrees))
            }

            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.25), radius: 1.5)
        }
        .frame(width: 46, height: 46)
    }
}

/// A fan/cone — apex at bottom-center (over the dot), spreading
/// toward the top. Rotated by the device heading so it points the
/// way the user is facing.
private struct HeadingWedge: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.55)
        )
        path.closeSubpath()
        return path
    }
}
