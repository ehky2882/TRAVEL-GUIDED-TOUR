import XCTest
import MapKit
@testable import TRAVEL_GUIDED_TOUR

/// Pins the two properties that made a coincident cluster swallow every
/// tap on the home map (Montreal / Dorchester Square, reported
/// 2026-08-17):
///
///  1. Markers at the same coordinate can never be separated by zoom, so
///     the map has to be told that rather than zooming forever.
///  2. Framing a cluster must always tighten the camera — the ~1.1 km
///     span floor used to *widen* it when the user was already closer in.
final class MapClusteringSeparationTests: XCTestCase {

    // MARK: - Helpers

    private func marker(
        _ latitude: Double,
        _ longitude: Double
    ) -> MapClustering.StopMarker {
        MapClustering.StopMarker(
            id: UUID(),
            tourId: UUID(),
            title: "Stop",
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }

    private func placeMarker(
        _ latitude: Double,
        _ longitude: Double,
        tours: Int = 2
    ) -> MapClustering.StopMarker {
        let placeId = UUID()
        return MapClustering.StopMarker(
            id: placeId,
            tourId: UUID(),
            title: "Dorchester Square",
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            placeId: placeId,
            placeTourCount: tours
        )
    }

    // MARK: - Places are never clustered

    /// 🔴 The bug this pins, reported on 1.1 (70): a place pin merged into an
    /// ordinary cluster with its neighbours, rendered as a plain count pin,
    /// and its tap went to the cluster handler — which only knows how to open
    /// tours. The place page became unreachable from that map entirely.
    ///
    /// Worst on a maker page, whose coarser grid over a whole-city region puts
    /// a downtown place in the same cell as several of the same maker's tours.
    func test_placeMarker_isNeverClusteredWithItsNeighbours() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.50, longitude: -73.57),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        // A place and three ordinary tours close enough to share one cell.
        let markers = [
            placeMarker(45.4997, -73.5710),
            marker(45.4999, -73.5712),
            marker(45.5001, -73.5708),
            marker(45.4995, -73.5715)
        ]
        let items = MapClustering.cluster(markers: markers, in: region, cellsAcross: 12)

        let places = items.compactMap { item -> MapClustering.StopMarker? in
            if case .single(let m) = item.kind, m.isPlace { return m }
            return nil
        }
        XCTAssertEqual(places.count, 1, "the place must survive as its own tappable pin")
        XCTAssertEqual(places.first?.placeTourCount, 2)

        // And no cluster may contain it — that is the state that hid it.
        for item in items {
            if case .cluster(_, let stops) = item.kind {
                XCTAssertFalse(stops.contains(where: \.isPlace),
                               "a place marker must never be bucketed into a cluster")
            }
        }
    }

    /// The ordinary tours around it still cluster — this fix must not turn
    /// every pin into a single.
    func test_ordinaryMarkersStillCluster() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.50, longitude: -73.57),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        let markers = [
            marker(45.4999, -73.5712),
            marker(45.5001, -73.5708),
            marker(45.4995, -73.5715)
        ]
        let items = MapClustering.cluster(markers: markers, in: region, cellsAcross: 12)
        XCTAssertTrue(
            items.contains { if case .cluster = $0.kind { return true } else { return false } },
            "neighbouring tour pins must still merge"
        )
    }

    // MARK: - canSeparateByZoom

    /// The real catalog case: a walk's intro stop wired at the exact
    /// coordinate of the single-stop tour of the same landmark.
    func test_canSeparateByZoom_coincidentMarkers_isFalse() {
        let stops = [marker(45.4997, -73.5710), marker(45.4997, -73.5710)]
        XCTAssertFalse(MapClustering.canSeparateByZoom(stops))
    }

    func test_canSeparateByZoom_distinctMarkers_isTrue() {
        // ~10 m apart — tight, but a deep enough camera splits them.
        let stops = [marker(45.4997, -73.5710), marker(45.4998, -73.5710)]
        XCTAssertTrue(MapClustering.canSeparateByZoom(stops))
    }

    /// Sub-centimetre float noise must not read as a real separation, or
    /// the map would zoom forever chasing a gap the user can't see.
    func test_canSeparateByZoom_floatNoise_isFalse() {
        let stops = [marker(45.4997, -73.5710), marker(45.4997 + 1e-9, -73.5710 - 1e-9)]
        XCTAssertFalse(MapClustering.canSeparateByZoom(stops))
    }

    func test_canSeparateByZoom_singleMarker_isTrue() {
        XCTAssertTrue(MapClustering.canSeparateByZoom([marker(45.4997, -73.5710)]))
    }

    // MARK: - region(framing:within:)

    /// The bug behind "tapping the pin does nothing": the caller was
    /// already tighter than the helper's 0.01° floor, so the tap zoomed
    /// *out* and re-rendered the same cluster.
    func test_regionFraming_neverWidensTheCamera() {
        let stops = [marker(45.4997, -73.5710), marker(45.49975, -73.5710)]
        let current = MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)

        guard let region = MapClustering.region(framing: stops, within: current) else {
            return XCTFail("expected a region")
        }
        XCTAssertLessThan(region.span.latitudeDelta, current.latitudeDelta)
        XCTAssertLessThan(region.span.longitudeDelta, current.longitudeDelta)
    }

    /// Every tap has to make visible progress, else the user taps twice
    /// and concludes the pin is dead.
    func test_regionFraming_tightensByAtLeastHalf() {
        let stops = [marker(45.4997, -73.5710), marker(45.49975, -73.5710)]
        let current = MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)

        guard let region = MapClustering.region(framing: stops, within: current) else {
            return XCTFail("expected a region")
        }
        XCTAssertLessThanOrEqual(region.span.latitudeDelta, current.latitudeDelta / 2)
        XCTAssertLessThanOrEqual(region.span.longitudeDelta, current.longitudeDelta / 2)
    }

    /// The clamp must not disturb the ordinary case — a cluster tapped
    /// from a wide camera still frames to the neighbourhood-level span
    /// the floor was written to produce, not to half the current span.
    func test_regionFraming_wideCamera_keepsNeighbourhoodFloor() {
        let stops = [marker(45.4997, -73.5710), marker(45.5000, -73.5710)]
        let current = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

        guard let region = MapClustering.region(framing: stops, within: current) else {
            return XCTFail("expected a region")
        }
        XCTAssertEqual(region.span.latitudeDelta, 0.01, accuracy: 1e-9)
    }

    /// Called without a current span (the maker map's old signature),
    /// behaviour is unchanged.
    func test_regionFraming_withoutCurrentSpan_isUnchanged() {
        let stops = [marker(45.4997, -73.5710), marker(45.5000, -73.5710)]

        guard let region = MapClustering.region(framing: stops) else {
            return XCTFail("expected a region")
        }
        XCTAssertEqual(region.span.latitudeDelta, 0.01, accuracy: 1e-9)
        XCTAssertEqual(region.center.latitude, 45.49985, accuracy: 1e-9)
    }

    // MARK: - needsDisambiguation (shared by both map surfaces)

    func test_needsDisambiguation_coincidentMarkers_isTrue_atAnyZoom() {
        let stops = [marker(45.4997, -73.5710), marker(45.4997, -73.5710)]
        for span in [1.0, 0.01, 0.0001] {
            XCTAssertTrue(
                MapClustering.needsDisambiguation(
                    stops: stops,
                    currentSpan: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
                ),
                "coincident markers can never be zoomed apart (span \(span))"
            )
        }
    }

    /// Separable markers at an ordinary zoom should still zoom, not open
    /// a stack — otherwise every cluster in the catalog stops behaving
    /// like a cluster.
    func test_needsDisambiguation_separableAtOrdinaryZoom_isFalse() {
        let stops = [marker(45.4997, -73.5710), marker(45.5000, -73.5710)]
        XCTAssertFalse(
            MapClustering.needsDisambiguation(
                stops: stops,
                currentSpan: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }

    /// Backstop: markers a metre or two apart, already at building scale.
    func test_needsDisambiguation_atBuildingScale_isTrue() {
        let stops = [marker(45.49970, -73.5710), marker(45.499701, -73.5710)]
        XCTAssertTrue(
            MapClustering.needsDisambiguation(
                stops: stops,
                currentSpan: MKCoordinateSpan(
                    latitudeDelta: MapClustering.buildingScaleSpan,
                    longitudeDelta: MapClustering.buildingScaleSpan
                )
            )
        )
    }

    func test_needsDisambiguation_noSpanYet_fallsBackToSeparability() {
        let separable = [marker(45.4997, -73.5710), marker(45.5000, -73.5710)]
        let coincident = [marker(45.4997, -73.5710), marker(45.4997, -73.5710)]
        XCTAssertFalse(MapClustering.needsDisambiguation(stops: separable, currentSpan: nil))
        XCTAssertTrue(MapClustering.needsDisambiguation(stops: coincident, currentSpan: nil))
    }

    // MARK: - Anchoring a pin low in the frame

    /// The maker map is only 320pt tall and a two-card stack is ~178pt,
    /// so the pin has to sit BELOW centre or the top card falls off the
    /// map. North is up, so the camera centre moves north of the pin.
    func test_regionAnchoring_putsPinBelowCentre() {
        let pin = CLLocationCoordinate2D(latitude: 45.4997, longitude: -73.5710)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

        let region = MapClustering.region(anchoring: pin, at: 0.72, span: span)

        XCTAssertGreaterThan(region.center.latitude, pin.latitude)
        XCTAssertEqual(region.center.longitude, pin.longitude, accuracy: 1e-9)
        XCTAssertEqual(region.span.latitudeDelta, span.latitudeDelta, accuracy: 1e-9)

        // The pin should land 72% of the way down from the map's top edge.
        let north = region.center.latitude + span.latitudeDelta / 2
        let fractionDown = (north - pin.latitude) / span.latitudeDelta
        XCTAssertEqual(fractionDown, 0.72, accuracy: 1e-9)
    }

    /// 0.5 is the plain recentre — unchanged behaviour for any caller
    /// that doesn't need room above.
    func test_regionAnchoring_atHalf_isAPlainRecentre() {
        let pin = CLLocationCoordinate2D(latitude: 45.4997, longitude: -73.5710)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MapClustering.region(anchoring: pin, at: 0.5, span: span)
        XCTAssertEqual(region.center.latitude, pin.latitude, accuracy: 1e-9)
    }

    func test_regionAnchoring_clampsToThePole() {
        let pin = CLLocationCoordinate2D(latitude: 89.9, longitude: 0)
        let span = MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        let region = MapClustering.region(anchoring: pin, at: 1.0, span: span)
        XCTAssertLessThanOrEqual(region.center.latitude, 90)
    }

    // MARK: - Clustering still merges coincident markers

    /// Sanity check on the premise: coincident markers stay one cluster
    /// no matter how tight the camera gets. This is *why*
    /// `canSeparateByZoom` has to exist.
    func test_coincidentMarkers_stayClustered_atEveryZoom() {
        let stops = [marker(45.4997, -73.5710), marker(45.4997, -73.5710)]
        for span in [1.0, 0.1, 0.01, 0.001, 0.0001, 0.00001] {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.4997, longitude: -73.5710),
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
            let items = MapClustering.cluster(markers: stops, in: region)
            XCTAssertEqual(items.count, 1, "expected one cluster at span \(span)")
            guard let kind = items.first?.kind else {
                return XCTFail("expected a cluster item at span \(span)")
            }
            switch kind {
            case .cluster(let count, _):
                XCTAssertEqual(count, 2, "span \(span)")
            case .single:
                XCTFail("coincident markers must never render as separate pins (span \(span))")
            }
        }
    }
}
