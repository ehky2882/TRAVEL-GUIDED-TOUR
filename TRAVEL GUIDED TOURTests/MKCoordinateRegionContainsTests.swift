import XCTest
import MapKit
@testable import TRAVEL_GUIDED_TOUR

/// Covers `MKCoordinateRegion.contains(_:)` — the dateline-safe
/// helper that replaced two identical naive bounding-box checks
/// (audit P1-7).
final class MKCoordinateRegionContainsTests: XCTestCase {

    // MARK: - Normal (non-wrapping) regions

    func test_contains_inside() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        XCTAssertTrue(region.contains(
            CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857)
        ))
    }

    func test_contains_outside_byLatitude() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        XCTAssertFalse(region.contains(
            CLLocationCoordinate2D(latitude: 41.5, longitude: -73.9857)
        ))
    }

    func test_contains_outside_byLongitude() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        XCTAssertFalse(region.contains(
            CLLocationCoordinate2D(latitude: 40.7484, longitude: -70.0)
        ))
    }

    // MARK: - Antimeridian-wrapping regions

    func test_contains_regionWrapsEast_pointJustEastOfDateline() {
        // Region centered at +179 with a 4° span → eastern edge would
        // be +181, which wraps to -179 in Apple's domain. A point at
        // -179.5 should be inside, even though a naive minLon/maxLon
        // check would miss it.
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 179),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        XCTAssertTrue(region.contains(
            CLLocationCoordinate2D(latitude: 0, longitude: -179.5)
        ))
    }

    func test_contains_regionWrapsEast_pointJustWestOfCenter() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 179),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        XCTAssertTrue(region.contains(
            CLLocationCoordinate2D(latitude: 0, longitude: 178)
        ))
    }

    func test_contains_regionWrapsEast_pointTooFarWest() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 179),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        // Outside the eastern side (would be wrapped to -179), and
        // not within the western side (177..180). Point at 170 is
        // truly outside.
        XCTAssertFalse(region.contains(
            CLLocationCoordinate2D(latitude: 0, longitude: 170)
        ))
    }

    func test_contains_regionWrapsWest_pointJustWestOfDateline() {
        // Region centered at -179 with a 4° span → western edge would
        // be -181, which wraps to +179. A point at +179.5 should be
        // inside.
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: -179),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        XCTAssertTrue(region.contains(
            CLLocationCoordinate2D(latitude: 0, longitude: 179.5)
        ))
    }

    func test_contains_regionWrapsWest_pointTooFarEast() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: -179),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        XCTAssertFalse(region.contains(
            CLLocationCoordinate2D(latitude: 0, longitude: -170)
        ))
    }
}
