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

    // MARK: - Places inside a cluster

    /// 🔴 The map must not under-report a region. A place marker stands for
    /// every tour at that site, so a cluster badge that counted it as one
    /// marker would say "2" where four tours sit.
    ///
    /// An earlier revision kept places out of clustering altogether, which
    /// made the same lie louder: at continental zoom a lone "2" capsule
    /// floated beside a "100" cluster, reading as though a whole region held
    /// two tours. Reported from a world-zoom screenshot.
    func test_clusterCount_countsToursNotMarkers() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.50, longitude: -73.57),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        // One place holding 2 tours, plus 2 ordinary tours, all in one cell.
        let markers = [
            placeMarker(45.4997, -73.5710, tours: 2),
            marker(45.4999, -73.5712),
            marker(45.5001, -73.5708)
        ]
        let items = MapClustering.cluster(markers: markers, in: region, cellsAcross: 12)

        let counts = items.compactMap { item -> Int? in
            if case .cluster(let count, _) = item.kind { return count }
            return nil
        }
        XCTAssertEqual(counts, [4], "2 place tours + 2 ordinary tours = 4, not 3 markers")
    }

    /// A place still clusters like anything else. It sits at a distinct
    /// coordinate from its neighbours — it REPLACES its own tours, so what
    /// surrounds it is other tours elsewhere — which means zooming separates
    /// it normally and it needs no exemption.
    func test_placeMarker_clustersWithItsNeighbours() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.50, longitude: -73.57),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        let markers = [
            placeMarker(45.4997, -73.5710),
            marker(45.4999, -73.5712)
        ]
        let items = MapClustering.cluster(markers: markers, in: region, cellsAcross: 12)
        XCTAssertEqual(items.count, 1, "a place near another pin merges like any other marker")
    }

    /// …and zooming in pulls it back out as its own tappable capsule, which is
    /// what makes clustering it safe.
    func test_placeMarker_separatesOnceZoomedIn() {
        let tight = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.4998, longitude: -73.5711),
            span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        )
        let markers = [
            placeMarker(45.4997, -73.5710),
            marker(45.4999, -73.5712)
        ]
        let items = MapClustering.cluster(markers: markers, in: tight, cellsAcross: 12)
        let places = items.compactMap { item -> MapClustering.StopMarker? in
            if case .single(let m) = item.kind, m.isPlace { return m }
            return nil
        }
        XCTAssertEqual(places.count, 1, "zoomed in, the place is its own pin again")
    }

    // MARK: - canSeparateByZoom    // MARK: - canSeparateByZoom

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
