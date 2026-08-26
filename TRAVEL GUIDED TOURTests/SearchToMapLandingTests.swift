import XCTest
import CoreLocation
import MapKit
@testable import TRAVEL_GUIDED_TOUR

/// Pins where the map lands, and where a tour's card anchors, when a tour is
/// tapped in Search.
///
/// WHY THIS EXISTS
/// ---------------
/// Owner, 2026-08-26: *"if I search for a tour and click on it, it takes me
/// straight to the tour details page… when I exit that page I go to my
/// previous map state, whereas I think it makes sense to be exiting to the
/// area of the map that tour lives in."*
///
/// So a tour result now flies the map to the tour and raises its placecard,
/// the same as tapping its pin. The card is a map annotation anchored to a
/// coordinate, so the coordinate has to be the one the PIN uses — anywhere
/// else and the card points at empty map.
final class SearchToMapLandingTests: XCTestCase {

    /// 🔴 A WALK'S CARD MUST ANCHOR ON ITS FIRST STOP, NOT ITS CENTROID.
    ///
    /// `MapMarkers` draws one pin per tour at its single stop, or at stop 0
    /// for a walk. A walk's centroid is the mean of stops that can be a
    /// kilometre apart — for the Montreal Downtown walk it sits 197 m from
    /// any of them (session 93). Anchoring the card there would float it over
    /// blank map with the real pin somewhere off to the side.
    func test_walkAnchorsOnStopZero_notItsCentroid() {
        let walk = TestFixtures.makeTour(
            title: "The Downtown Loop",
            kind: .multiStop,
            stopCoordinates: [
                (latitude: 45.5000, longitude: -73.5700),   // order 0
                (latitude: 45.5100, longitude: -73.5500),
                (latitude: 45.5200, longitude: -73.5300),
            ],
            centroidLatitude: 45.5100,
            centroidLongitude: -73.5500
        )

        let anchor = HomeView.placecardCoordinate(for: walk)
        XCTAssertEqual(anchor?.latitude ?? 0, 45.5000, accuracy: 1e-6)
        XCTAssertEqual(anchor?.longitude ?? 0, -73.5700, accuracy: 1e-6)
    }

    func test_singleStopAnchorsOnItsStop() {
        let tour = TestFixtures.makeTour(
            title: "Casa Batllo",
            latitude: 41.3917,
            longitude: 2.1650
        )

        let anchor = HomeView.placecardCoordinate(for: tour)
        XCTAssertEqual(anchor?.latitude ?? 0, 41.3917, accuracy: 1e-6)
        XCTAssertEqual(anchor?.longitude ?? 0, 2.1650, accuracy: 1e-6)
    }

    /// The landing region centres on the pin at a neighbourhood zoom — close
    /// enough to read as "here it is", not a continent and not a doorstep.
    func test_landingRegion_centresOnThePinAtNeighbourhoodZoom() {
        let tour = TestFixtures.makeTour(
            title: "The Barbican",
            latitude: 51.5200,
            longitude: -0.0937
        )

        guard let region = HomeView.region(framing: tour) else {
            return XCTFail("a tour with a stop must produce a region")
        }
        XCTAssertEqual(region.center.latitude, 51.5200, accuracy: 1e-6)
        XCTAssertEqual(region.center.longitude, -0.0937, accuracy: 1e-6)
        XCTAssertGreaterThan(region.span.latitudeDelta, 0)
        XCTAssertLessThan(region.span.latitudeDelta, 0.5,
                          "a whole-city-or-wider span would lose the pin")
    }

    /// ⚠️ The fallback that keeps the feature from silently doing nothing.
    /// A tour with no stops cannot be put on the map; `SearchView` opens it
    /// directly instead, which needs this to report nil rather than guess.
    func test_tourWithNoStops_hasNoRegion() {
        let stopless = TestFixtures.makeTour(title: "Stopless", stopCount: 0)

        XCTAssertNil(HomeView.placecardCoordinate(for: stopless))
        XCTAssertNil(HomeView.region(framing: stopless))
    }

    /// The move carries the tour through to arrival. It cannot be set before
    /// the flight: `HomeView.flyTo` opens by clearing any existing card, so a
    /// card raised by the caller is wiped by the move itself.
    func test_pendingMapMove_carriesTheTourItShouldOpen() {
        let id = UUID()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.52, longitude: -0.09),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        XCTAssertEqual(PendingMapMove(region: region, placecardTourId: id).placecardTourId, id)
        XCTAssertNil(PendingMapMove(region: region).placecardTourId,
                     "a plain city search still carries no card")
    }
}
