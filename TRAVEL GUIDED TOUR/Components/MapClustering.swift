import CoreLocation
import Foundation
import MapKit

/// Grid clustering for map pins, shared by every map surface.
///
/// Extracted from `HomeMapSection` on 2026-07-27 so the maker page's map
/// could reuse it rather than reimplement it. Everything here is pure
/// and `static` — it was already written that way, which is why the move
/// was a straight lift.
///
/// The two subtle properties this pipeline exists to preserve, both
/// hard-won on the home map and easy to break by "simplifying":
///
///  1. **Absolute grid origin.** Buckets are keyed off (lat 0, lon 0),
///     never off the visible region's corner, so a marker's bucket —
///     and therefore its SwiftUI annotation ID — depends only on its
///     coordinate and the current cell pitch. A pan with no zoom change
///     keeps every cluster ID stable, so SwiftUI updates annotations in
///     place instead of removing and re-adding them.
///  2. **Snapped span.** Cell pitch derives from a span rounded to two
///     significant figures, because MapKit reports sub-percent drift on
///     the span when a pan settles — and any pitch change re-buckets
///     markers near a cell boundary, which looks like clusters shifting
///     on a pure pan.
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

    struct BucketKey: Hashable {
        let row: Int
        let col: Int
    }

    /// Either a single marker or a merged group, with a stable `id` for
    /// SwiftUI's annotation diffing.
    struct ClusterItem: Identifiable {
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

    // MARK: - Tuning

    /// Cells across the visible region at the default density. Finer
    /// than the original 14 so pins only cluster when they're very close
    /// together — reduces false merges at neighbourhood zoom.
    ///
    /// ⚠️ This counts cells across the **region**, not the screen, so a
    /// physically shorter map covers the same 20 cells in far fewer
    /// points and visually adjacent pins refuse to merge. Small maps
    /// should pass a lower value.
    static let defaultCellsAcross: Double = 20

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
    /// about 65 m across, where the cluster grid's cells are only a few
    /// metres wide. Past this, asking the user to pinch further to tease
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

    /// Round `span` to two significant figures so MapKit's
    /// sub-percent settle drift on pure pans doesn't perturb the
    /// derived cluster cell pitch. A real pinch step changes span
    /// by at least several percent — well above this snap precision
    /// — so legitimate zoom changes still cross a snap boundary.
    /// E.g. 0.0050 / 0.005001 / 0.00499 all snap to 0.0050; 0.006
    /// remains 0.006.
    static func snappedSpan(_ span: Double) -> Double {
        guard span > 0, span.isFinite else { return span }
        // Scale so the first two sig figs become the integer part,
        // round, then scale back.
        let exponent = floor(log10(span)) - 1
        let unit = pow(10.0, exponent)
        return (span / unit).rounded() * unit
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

    static func cluster(
        markers: [StopMarker],
        in region: MKCoordinateRegion?,
        cellsAcross: Double = defaultCellsAcross
    ) -> [ClusterItem] {
        guard let region else {
            return markers.map { ClusterItem(coordinate: $0.coordinate, kind: .single($0)) }
        }

        // Viewport cull. Drop markers that are far outside the visible
        // region before doing any bucketing so the annotation set the
        // map builds/diffs scales with what's near the viewport, not
        // with the whole (multi-city, ~1,000-stop) catalog. MapKit
        // already culls off-screen annotations from *drawing*, but
        // SwiftUI still builds + diffs an annotation for every one on
        // each recompute — wasted work once the catalog spans continents.
        // The margin (see `cullMarginViewports`) keeps a generous ring of
        // off-screen markers so pins never visibly "pop in" at the edges
        // during a normal pan. Bucketing uses an absolute grid origin
        // (below), so culling never changes a surviving marker's bucket
        // key — cluster IDs stay stable and pans still update in place.
        let visibleMarkers: [StopMarker]
        if region.span.latitudeDelta < cullDisableSpan,
           region.span.longitudeDelta < cullDisableSpan {
            let window = expandedWindow(region, byViewports: cullMarginViewports)
            visibleMarkers = markers.filter { window.contains($0.coordinate) }
        } else {
            visibleMarkers = markers
        }

        // Snap span to two significant figures BEFORE deriving cell
        // pitch. MapKit reports sub-percent drift on the span when a
        // pan gesture settles (even when the user didn't zoom), and
        // ANY change in pitch re-buckets markers that sit near a
        // cell boundary — the visible symptom is clusters appearing
        // to shift / reform on pure pans. Two sig figs is coarse
        // enough to absorb that drift, fine enough that real zoom
        // changes (always at least several percent per pinch step)
        // still cross a snap boundary and re-cluster as expected.
        let snappedLatSpan = snappedSpan(region.span.latitudeDelta)
        let snappedLonSpan = snappedSpan(region.span.longitudeDelta)
        let cellSpanLat = snappedLatSpan / cellsAcross
        let cellSpanLon = snappedLonSpan / cellsAcross
        guard cellSpanLat > 0, cellSpanLon > 0 else {
            return visibleMarkers.map { ClusterItem(coordinate: $0.coordinate, kind: .single($0)) }
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
        // 🔴 A PLACE MARKER IS NEVER BUCKETED, and that is load-bearing.
        //
        // A place pin is already a cluster — it says "N tours here" and it is
        // the only route to the place page. Let it merge into an ordinary
        // cluster and it renders as a plain count pin whose tap goes to the
        // cluster handler, which knows only about tours: the place becomes
        // unreachable, silently. That shipped in 1.1 (69) and (70).
        //
        // It bit the maker map first because that map uses a coarser grid (12
        // cells across) over a region framed to fit a maker's ENTIRE body of
        // work, so cells are often ~900 m and a downtown place always has a
        // neighbour. The home map has the same latent bug at low zoom.
        //
        // Keeping places single costs nothing: there are 24 in the catalog, so
        // this can never produce a wall of pins, and a capsule overlapping a
        // nearby cluster reads far better than a destination you cannot open.
        var buckets: [BucketKey: [StopMarker]] = [:]
        var placeItems: [ClusterItem] = []
        for marker in visibleMarkers {
            if marker.isPlace {
                placeItems.append(ClusterItem(coordinate: marker.coordinate, kind: .single(marker)))
                continue
            }
            let row = Int(floor(marker.coordinate.latitude / cellSpanLat))
            let col = Int(floor(marker.coordinate.longitude / cellSpanLon))
            buckets[BucketKey(row: row, col: col), default: []].append(marker)
        }

        return placeItems + buckets.map { key, stops in
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
        // whenever they sit closer together than one cell (span /
        // cellsAcross), so a cluster can form at a span far below the
        // 0.01° (~1.1 km) floor above — and framing it then *widened*
        // the camera. The user tapped a pin, got zoomed out, and saw the
        // same cluster re-render: indistinguishable from the tap doing
        // nothing. Clamping to half the current span keeps the floor's
        // intent (no single tap drops you into a one-block view) while
        // guaranteeing every tap makes progress.
        //
        // The clamp only ever binds when the floor was the thing
        // widening the camera: a real cluster's bounding box is at most
        // one cell across, so its padded span is ~span/8 — already well
        // inside half the current span.
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
