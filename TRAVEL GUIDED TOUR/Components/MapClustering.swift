import CoreLocation
import Foundation
import MapKit

/// Screen-space clustering for map pins, shared by every map surface.
///
/// Extracted from `HomeMapSection` on 2026-07-27 so the maker page's map
/// could reuse it rather than reimplement it.
///
/// **Rewritten 2026-09-19** from a lat/lon grid to greedy radius clustering
/// in projected (Mercator) space, because the grid could not keep up with a
/// catalogue of ~3,600 markers: at 20 cells across a 390pt map a cell was
/// ~20pt wide while a cluster badge is 36–44pt, so neighbouring clusters
/// drew on top of each other across the whole of Manhattan, and two pins a
/// hair apart on either side of a cell line never merged at all.
///
/// The properties this pipeline exists to preserve — easy to break by
/// "simplifying":
///
///  1. **The radius is in screen points.** A pin merges with anything
///     within `defaultClusterRadius` points of it on screen, whatever the
///     map's size — which is why callers pass the map's width. (The grid
///     counted cells across the *region*, so a short map needed its own
///     hand-tuned density; the maker map's `cellsAcross: 12` is gone.)
///  2. **Zoom is quantised, and the whole set is clustered.** The radius is
///     derived from a zoom level snapped to half-steps, and clustering runs
///     over every marker, not only the ones near the viewport. So the
///     grouping depends on the zoom level alone: a pan with no zoom change
///     yields identical clusters with identical IDs, and SwiftUI updates
///     annotations in place instead of removing and re-adding them. The
///     viewport cull is applied to the *output*.
enum MapClustering {

    // MARK: - A marker

    /// One tappable point on a map: a stop, carrying the tour it opens.
    struct StopMarker: Identifiable, Hashable {
        let id: UUID
        let tourId: UUID
        let title: String
        let coordinate: CLLocationCoordinate2D
        /// Set when this marker stands for a **place** — a site several tours
        /// describe — rather than a single tour. The map draws a different pin
        /// and a tap opens the place instead of a tour.
        let placeId: UUID?
        /// How many tours the place holds. Zero for an ordinary tour marker.
        let placeTourCount: Int

        var isPlace: Bool { placeId != nil }

        init(
            id: UUID,
            tourId: UUID,
            title: String,
            coordinate: CLLocationCoordinate2D,
            placeId: UUID? = nil,
            placeTourCount: Int = 0
        ) {
            self.id = id
            self.tourId = tourId
            self.title = title
            self.coordinate = coordinate
            self.placeId = placeId
            self.placeTourCount = placeTourCount
        }

        static func == (lhs: StopMarker, rhs: StopMarker) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    /// Either a single marker or a merged group, with a stable `id` for
    /// SwiftUI's annotation diffing.
    struct ClusterItem: Identifiable {
        let coordinate: CLLocationCoordinate2D
        let kind: Kind
        /// The zoom step the cluster was formed at. Part of a cluster's ID,
        /// because the same seed gathers different members at another zoom.
        private let zoomStep: Int

        init(coordinate: CLLocationCoordinate2D, kind: Kind, zoomStep: Int = 0) {
            self.coordinate = coordinate
            self.kind = kind
            self.zoomStep = zoomStep
        }

        enum Kind {
            case single(StopMarker)
            /// `stops.first` is the cluster's seed — the marker that gathered
            /// the rest — which is what keeps its ID stable.
            case cluster(count: Int, stops: [StopMarker])
        }

        var id: String {
            switch kind {
            case .single(let m): return "s-\(m.id.uuidString)"
            case .cluster(let count, let stops):
                let seed = stops.first?.id.uuidString ?? "n"
                return "c-\(seed)-z\(zoomStep)-\(count)"
            }
        }

        var accessibilityLabel: String {
            switch kind {
            case .single(let m): return m.title
            case .cluster(let count, _): return "\(count) tours"
            }
        }
    }

    // MARK: - Tuning

    /// Two pins closer than this on screen, in points, merge. Sized to the
    /// pins themselves: a cluster badge's core is 26–38pt across (36–48pt
    /// with its halo), so anything much tighter lets them overlap. Seeds end
    /// up at least this far apart; a cluster is then drawn at its members'
    /// centroid, which can pull two badges somewhat closer.
    ///
    /// Owner-tuned 2026-09-19: 56 on TestFlight 175 read slightly too
    /// clumped ("a touch less, a little more circles"), so 48.
    static let defaultClusterRadius: Double = 48

    /// Map width assumed before the real one has been measured — an
    /// iPhone's portrait width. Only matters for the first frame.
    static let fallbackMapWidth: Double = 390

    /// Zoom quantisation, in steps per doubling of scale. 2 = half-steps, so
    /// the on-screen radius wanders at most ±19% between steps, and a pan's
    /// sub-percent span drift almost never lands on a step boundary.
    static let zoomStepsPerDoubling: Double = 2

    /// Above this span (in degrees) the viewport cull is switched off:
    /// the expanded window would approach global, so culling saves
    /// nothing and clustering already collapses the set at that zoom.
    static let cullDisableSpan: Double = 30

    /// Viewports of margin added on every side of the visible region
    /// before culling. 1.0 = keep a 3×-wide / 3×-tall window (one full
    /// viewport of buffer beyond every edge), so a marker is already in
    /// the annotation set long before it pans on-screen — the cull is
    /// invisible under normal panning.
    static let cullMarginViewports: Double = 1.0

    /// Coordinate delta below which two markers are the same point as
    /// far as any map camera is concerned (~1 cm). This is a
    /// float-equality epsilon, **not** a UX threshold — it sits far
    /// below the precision of any coordinate the catalog stores.
    static let coincidentEpsilon: Double = 1e-7

    // MARK: - Separability

    /// Whether zooming in can ever pull `stops` apart into separate pins.
    ///
    /// 🔴 Bucketing is a grid over coordinates, so markers at the *same*
    /// coordinate share a cell at **every** cell pitch: no camera can
    /// separate them, and a cluster tap that only zooms is an infinite
    /// no-op — the pin swallows every tap and neither tour is reachable
    /// from the map. Callers must offer another way in when this returns
    /// false (the home map stacks one placecard per tour).
    ///
    /// This is not hypothetical: **24 coincident pairs exist in the
    /// catalog today**, every one a walk whose intro stop is wired at the
    /// coordinate of the single-stop tour of the same landmark — Dam
    /// Square, the Colosseum, the CN Tower, Brandenburg Gate, Dorchester
    /// Square, and so on. That wiring is correct (the walk really does
    /// begin there); the map is what has to cope.
    ///
    /// Returns `true` for fewer than two markers — nothing to separate.
    static func canSeparateByZoom(_ stops: [StopMarker]) -> Bool {
        guard stops.count > 1 else { return true }
        let lats = stops.map(\.coordinate.latitude)
        let lons = stops.map(\.coordinate.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return true }
        return (maxLat - minLat) > coincidentEpsilon
            || (maxLon - minLon) > coincidentEpsilon
    }

    /// Span (in degrees) at which the camera has reached building scale —
    /// about 65 m across, where the cluster radius covers only
    /// about ten metres. Past this, asking the user to pinch further to tease
    /// two pins apart stops being a reasonable ask.
    static let buildingScaleSpan: Double = 0.0006

    /// Whether a tapped cluster should be handed to the UI to
    /// disambiguate rather than zoomed into.
    ///
    /// Both map surfaces ask this one question so the rule can't drift
    /// between them: the home map answers it with a stack of place cards
    /// above the pin, and the maker map now does the same. Zooming stays
    /// the answer for every ordinary cluster.
    static func needsDisambiguation(
        stops: [StopMarker],
        currentSpan: MKCoordinateSpan?
    ) -> Bool {
        // Coincident members: no camera anywhere can separate them.
        if !canSeparateByZoom(stops) { return true }
        // Already at building scale: another zoom step isn't a fair ask.
        guard let currentSpan else { return false }
        return currentSpan.latitudeDelta <= buildingScaleSpan
            && currentSpan.longitudeDelta <= buildingScaleSpan
    }

    // MARK: - Geometry helpers

    /// The zoom step for a camera: log2 of degrees-per-point, quantised.
    /// Depends only on the span and the map's width, never on where the
    /// camera is, so a pure pan keeps the same step.
    static func zoomStep(lonSpan: Double, mapWidth: Double) -> Int {
        let width = mapWidth > 0 ? mapWidth : fallbackMapWidth
        let degreesPerPoint = min(360, max(lonSpan, 1e-9)) / width
        return Int((log2(degreesPerPoint) * zoomStepsPerDoubling).rounded())
    }

    /// Mercator map points per screen point at a zoom step.
    static func mapPointsPerPoint(atZoomStep step: Int) -> Double {
        let degreesPerPoint = pow(2, Double(step) / zoomStepsPerDoubling)
        return degreesPerPoint / 360 * MKMapSize.world.width
    }

    /// The visible region grown by `byViewports` viewports on every
    /// side. Used to decide which markers are close enough to the
    /// viewport to bother building an annotation for.
    static func expandedWindow(_ region: MKCoordinateRegion, byViewports v: Double) -> MKCoordinateRegion {
        let factor = 1 + 2 * v
        return MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(180, region.span.latitudeDelta * factor),
                longitudeDelta: min(360, region.span.longitudeDelta * factor)
            )
        )
    }

    // MARK: - Clustering

    /// Cluster `markers` for a map showing `region` at `mapWidth` points
    /// wide. Returns only what falls near the viewport.
    static func cluster(
        markers: [StopMarker],
        in region: MKCoordinateRegion?,
        mapWidth: Double,
        radius: Double = defaultClusterRadius
    ) -> [ClusterItem] {
        guard let region else {
            return markers.map { ClusterItem(coordinate: $0.coordinate, kind: .single($0)) }
        }

        let step = zoomStep(lonSpan: region.span.longitudeDelta, mapWidth: mapWidth)
        let items = clusterAll(markers: markers, zoomStep: step, radius: radius)

        // Viewport cull, on the OUTPUT. SwiftUI builds and diffs an
        // annotation for every item on each recompute, so the set handed
        // to the map must scale with what is near the viewport rather than
        // with the whole multi-continent catalogue. Culling after
        // clustering (not before) is what keeps a pan from changing any
        // cluster's membership — see the type's doc comment.
        guard region.span.latitudeDelta < cullDisableSpan,
              region.span.longitudeDelta < cullDisableSpan else { return items }
        let window = expandedWindow(region, byViewports: cullMarginViewports)
        return items.filter { window.contains($0.coordinate) }
    }

    /// Last full clustering, reused while the zoom step and markers are
    /// unchanged — i.e. across every pan, and every re-render that is not
    /// a zoom or a filter change.
    private static var memo: (markers: [StopMarker], step: Int, radius: Double, items: [ClusterItem])?

    /// Greedy radius clustering over every marker, in Mercator space.
    ///
    /// Each unclaimed marker, in input order, becomes a seed and gathers
    /// every unclaimed marker within `radius` screen points of it. A grid
    /// of `radius`-sized cells means each seed checks only its 3×3
    /// neighbourhood, so a pass over the whole catalogue is linear.
    /// Input order is the catalogue's, so the result is deterministic.
    static func clusterAll(markers: [StopMarker], zoomStep step: Int, radius: Double) -> [ClusterItem] {
        if let memo, memo.step == step, memo.radius == radius, memo.markers == markers {
            return memo.items
        }

        let cell = radius * mapPointsPerPoint(atZoomStep: step)
        guard cell > 0, cell.isFinite else {
            return markers.map { ClusterItem(coordinate: $0.coordinate, kind: .single($0)) }
        }
        let points = markers.map { MKMapPoint($0.coordinate) }

        struct Cell: Hashable { let x: Int; let y: Int }
        func cellOf(_ p: MKMapPoint) -> Cell {
            Cell(x: Int(floor(p.x / cell)), y: Int(floor(p.y / cell)))
        }
        var grid: [Cell: [Int]] = [:]
        grid.reserveCapacity(markers.count)
        for (i, p) in points.enumerated() {
            grid[cellOf(p), default: []].append(i)
        }

        var claimed = [Bool](repeating: false, count: markers.count)
        var items: [ClusterItem] = []
        let radiusSquared = cell * cell

        for seed in markers.indices where !claimed[seed] {
            claimed[seed] = true
            var members = [seed]
            let home = cellOf(points[seed])
            for dx in -1...1 {
                for dy in -1...1 {
                    guard let candidates = grid[Cell(x: home.x + dx, y: home.y + dy)] else { continue }
                    for j in candidates where !claimed[j] {
                        let ddx = points[j].x - points[seed].x
                        let ddy = points[j].y - points[seed].y
                        if ddx * ddx + ddy * ddy <= radiusSquared {
                            claimed[j] = true
                            members.append(j)
                        }
                    }
                }
            }

            if members.count == 1 {
                items.append(ClusterItem(coordinate: markers[seed].coordinate, kind: .single(markers[seed])))
                continue
            }
            let stops = members.map { markers[$0] }
            let avgLat = stops.reduce(0) { $0 + $1.coordinate.latitude } / Double(stops.count)
            let avgLon = stops.reduce(0) { $0 + $1.coordinate.longitude } / Double(stops.count)
            // Count TOURS, not markers. A place marker stands for every tour
            // at that site, so counting it as 1 would under-report a region.
            // Places cluster like anything else: a place sits at a distinct
            // coordinate from its neighbours (it REPLACES its own tours), so
            // zooming separates it normally (#536).
            let tourCount = stops.reduce(0) { $0 + ($1.isPlace ? $1.placeTourCount : 1) }
            items.append(ClusterItem(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                kind: .cluster(count: tourCount, stops: stops),
                zoomStep: step
            ))
        }

        memo = (markers, step, radius, items)
        return items
    }

    // MARK: - Camera

    /// Tighten the camera around a group of markers so a tapped cluster
    /// breaks apart on the next render. Mirrors MKMapView's default
    /// cluster-tap behavior. Returns `nil` for an empty group.
    ///
    /// Pass `within:` — the camera's current span — so the result is
    /// guaranteed to be a zoom **in**. See the clamp below for why that
    /// isn't automatic.
    static func region(
        framing stops: [StopMarker],
        within current: MKCoordinateSpan? = nil
    ) -> MKCoordinateRegion? {
        guard !stops.isEmpty else { return nil }
        let lats = stops.map(\.coordinate.latitude)
        let lons = stops.map(\.coordinate.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        // Pad by 2.5x so the cluster doesn't hug the edges, and floor
        // at a span that's roughly neighborhood-level — keeps a single
        // tap from over-zooming into a 1-block view.
        var latDelta = max((maxLat - minLat) * 2.5, 0.01)
        var lonDelta = max((maxLon - minLon) * 2.5, 0.01)

        // 🔴 A cluster tap must always TIGHTEN the camera. Markers merge
        // whenever they sit within the cluster radius on screen, so a
        // cluster can form at a span far below the
        // 0.01° (~1.1 km) floor above — and framing it then *widened*
        // the camera. The user tapped a pin, got zoomed out, and saw the
        // same cluster re-render: indistinguishable from the tap doing
        // nothing. Clamping to half the current span keeps the floor's
        // intent (no single tap drops you into a one-block view) while
        // guaranteeing every tap makes progress.
        //
        // A cluster's bounding box is at most two radii (~100pt) across,
        // so on a phone-width map the padded framing can exceed half the
        // current span and the clamp binds — that is fine: every tap still
        // at least doubles the zoom, which doubles the on-screen distance
        // between members and splits any pair further apart than one radius.
        if let current, current.latitudeDelta > 0, current.longitudeDelta > 0 {
            latDelta = min(latDelta, current.latitudeDelta / 2)
            lonDelta = min(lonDelta, current.longitudeDelta / 2)
        }

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    /// A region that puts `coordinate` `fraction` of the way DOWN the
    /// map rather than at its centre, keeping the span unchanged.
    ///
    /// Opens room above a pin for something anchored to it. The maker
    /// map needs this: its map is only 320pt tall, and a stack of two
    /// place cards is ~178pt, so a pin recentred the ordinary way (at
    /// 0.5, leaving 160pt above) would push the top card off the map.
    ///
    /// `fraction` 0.5 is the plain recentre; larger values sit the pin
    /// lower. Latitude is clamped to the poles.
    static func region(
        anchoring coordinate: CLLocationCoordinate2D,
        at fraction: Double,
        span: MKCoordinateSpan
    ) -> MKCoordinateRegion {
        // North is up, so to push the pin DOWN the screen the camera
        // centre moves NORTH of it — by however far past the middle we
        // want the pin to sit.
        let shift = (fraction - 0.5) * span.latitudeDelta
        let latitude = min(90, max(-90, coordinate.latitude + shift))
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: coordinate.longitude),
            span: span
        )
    }

    /// Frame an arbitrary set of coordinates — used to open a map
    /// already showing everything it holds. Padded generously and
    /// floored so a single point doesn't produce a street-level view.
    ///
    /// A maker whose tours span continents legitimately gets a
    /// world-scale region here; that is the correct picture of them.
    static func region(containing coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: min(180, max((maxLat - minLat) * 1.4, 0.02)),
            longitudeDelta: min(360, max((maxLon - minLon) * 1.4, 0.02))
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
