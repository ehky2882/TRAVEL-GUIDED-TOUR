import XCTest
import MapKit
import CoreLocation
@testable import TRAVEL_GUIDED_TOUR

/// Covers `MapRegionGeometry.anyStop(of:inside:)` — the check behind
/// the "No Atlas tours here yet" overlay. (Point-in-region containment
/// itself is covered by `MKCoordinateRegionContainsTests`.)
final class MapRegionGeometryTests: XCTestCase {

    /// A ~0.1° box centered on Times Square.
    private let nycRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    func testAnyStopTrueWhenTourInRegion() {
        let inside = TestFixtures.makeTour(latitude: 40.7484, longitude: -73.9857)
        XCTAssertTrue(MapRegionGeometry.anyStop(of: [inside], inside: nycRegion))
    }

    func testAnyStopFalseWhenAllToursOutside() {
        let london = TestFixtures.makeTour(latitude: 51.5074, longitude: -0.1278)
        let porto = TestFixtures.makeTour(latitude: 41.1579, longitude: -8.6291)
        XCTAssertFalse(MapRegionGeometry.anyStop(of: [london, porto], inside: nycRegion))
    }

    func testAnyStopFalseWhenNoTours() {
        XCTAssertFalse(MapRegionGeometry.anyStop(of: [], inside: nycRegion))
    }

    func testAnyStopTrueWhenAnyOfSeveralToursInRegion() {
        let london = TestFixtures.makeTour(latitude: 51.5074, longitude: -0.1278)
        let nyc = TestFixtures.makeTour(latitude: 40.7580, longitude: -73.9855)
        XCTAssertTrue(MapRegionGeometry.anyStop(of: [london, nyc], inside: nycRegion))
    }
}
