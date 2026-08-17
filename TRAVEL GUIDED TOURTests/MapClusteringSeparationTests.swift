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
