import XCTest
import CoreLocation
import MapKit
@testable import TRAVEL_GUIDED_TOUR

/// Pins where the **expand** control on an inline map lands you.
///
/// WHY THIS EXISTS
/// ---------------
/// Owner, 2026-08-30: *"in the 'map' view i want to be able to click on a
/// button that 'expands' the map which effectively takes me back to the home
/// map view at the location of that particular item … with the placecard
/// showing, similar to if i were to get to a tour by searching."*
///
/// The landing is the same `PendingMapMove` Search writes, so these guard the
/// two things that differ: framing a whole *set* of tours (a creator page, a
/// list), and carrying a **place** id rather than a tour id.
final class MapExpandTests: XCTestCase {

    // MARK: - Framing a set

    /// 🔴 THE SET IS FRAMED ON PIN COORDINATES, NOT EVERY STOP AND NOT THE
    /// CENTROID. `MapMarkers` draws one pin per tour — at its single stop, or
    /// at **stop 0** for a walk — so anything else frames ground the Home map
    /// has no pin on. A walk's centroid can sit hundreds of metres from any of
    /// its stops (Montreal's Downtown walk: 197 m), which is the bug session
    /// 102 fixed in the drawer, and it is the same mistake here.
    func test_framingASet_usesPinCoordinates_notCentroids() {
        let walk = TestFixtures.makeTour(
            title: "The Downtown Loop",
            kind: .multiStop,
            stopCoordinates: [
                (latitude: 45.5000, longitude: -73.5700),   // order 0 — the pin
                (latitude: 45.5100, longitude: -73.5500),
                (latitude: 45.5200, longitude: -73.5300),
            ],
            centroidLatitude: 45.9999,
            centroidLongitude: -73.0001
        )
        let single = TestFixtures.makeTour(
            title: "Square Saint-Louis",
            latitude: 45.5180,
            longitude: -73.5690
        )

        guard let frame = MapExpander.regionFraming([walk, single]) else {
            return XCTFail("expected a region")
        }

        // Centre sits between stop 0 of the walk and the single's only stop.
        XCTAssertEqual(frame.center.latitude, (45.5000 + 45.5180) / 2, accuracy: 0.0001)
        XCTAssertEqual(frame.center.longitude, (-73.5700 + -73.5690) / 2, accuracy: 0.0001)
        // The rogue centroid is nowhere near — if it had been used the centre
        // would be well north of both pins.
        XCTAssertLessThan(frame.center.latitude, 45.6)
    }

    /// Both members are inside the frame, which is the whole point of "show me
    /// all of this creator's work".
    func test_framingASet_containsEveryPin() {
        let a = TestFixtures.makeTour(title: "A", latitude: 51.5007, longitude: -0.1246)
        let b = TestFixtures.makeTour(title: "B", latitude: 51.5194, longitude: -0.1270)

        guard let frame = MapExpander.regionFraming([a, b]) else {
            return XCTFail("expected a region")
        }
        let halfLat = frame.span.latitudeDelta / 2
        let halfLon = frame.span.longitudeDelta / 2

        for tour in [a, b] {
            guard let pin = HomeView.placecardCoordinate(for: tour) else {
                return XCTFail("every fixture has a pin")
            }
            XCTAssertLessThanOrEqual(abs(pin.latitude - frame.center.latitude), halfLat)
            XCTAssertLessThanOrEqual(abs(pin.longitude - frame.center.longitude), halfLon)
        }
    }

    /// ⚠️ The guard that keeps the control from shipping as a dead button.
    /// A creator with nothing published, or a list of tours that cannot be
    /// placed, has nothing to expand to — `TourSetMap` hides the control on
    /// exactly this signal, so it must report nil rather than a default region.
    func test_framingNothing_hasNoRegion() {
        XCTAssertNil(MapExpander.regionFraming([]))
        XCTAssertNil(
            MapExpander.regionFraming([TestFixtures.makeTour(title: "Stopless", stopCount: 0)]),
            "a tour with no stops cannot be put on a map"
        )
    }

    /// A single tour still gets a usable frame rather than a degenerate
    /// zero-span one — `MapClustering.region(containing:)` floors the span.
    func test_framingOneTour_isNotZeroSpan() {
        let solo = TestFixtures.makeTour(title: "Solo", latitude: 35.6586, longitude: 139.7454)
        guard let frame = MapExpander.regionFraming([solo]) else {
            return XCTFail("expected a region")
        }
        XCTAssertGreaterThan(frame.span.latitudeDelta, 0)
        XCTAssertGreaterThan(frame.span.longitudeDelta, 0)
    }

    // MARK: - Which card comes up

    /// The place page's expand carries a **place** id, not a tour id. A site
    /// with two or more tours draws as one capsule pin on the Home map, so a
    /// member tour's card would hang over a pin that stands for the place.
    func test_pendingMapMove_carriesAPlaceSeparatelyFromATour() {
        let placeId = UUID()
        let tourId = UUID()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.3705, longitude: 2.1500),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        let place = PendingMapMove(region: region, placecardPlaceId: placeId)
        XCTAssertEqual(place.placecardPlaceId, placeId)
        XCTAssertNil(place.placecardTourId)

        let tour = PendingMapMove(region: region, placecardTourId: tourId)
        XCTAssertEqual(tour.placecardTourId, tourId)
        XCTAssertNil(tour.placecardPlaceId)

        XCTAssertNil(PendingMapMove(region: region).placecardPlaceId,
                     "expanding a creator or a list raises no card at all")
    }

    /// Two expands to the *same* region must register as distinct events, or
    /// the second one silently does nothing — `.onChange` compares on the id.
    func test_twoExpandsToTheSamePlace_areDistinctEvents() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        XCTAssertNotEqual(
            PendingMapMove(region: region),
            PendingMapMove(region: region)
        )
    }

    // MARK: - The channel

    /// The expander does nothing until `ContentView` wires it, and says so —
    /// call sites hide the control on `isAvailable` rather than drawing one
    /// that cannot act.
    func test_unwiredExpander_isUnavailableAndInert() {
        let expander = MapExpander()
        XCTAssertFalse(expander.isAvailable)
        // Must not trap.
        expander.expand(framing: [TestFixtures.makeTour(title: "A")])
    }

    /// Wired, it hands the caller's landing straight through.
    func test_wiredExpander_deliversTheMove() {
        let expander = MapExpander()
        var delivered: [PendingMapMove] = []
        expander.performExpand = { delivered.append($0) }

        XCTAssertTrue(expander.isAvailable)

        let placeId = UUID()
        expander.expand(
            to: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 1, longitude: 2),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ),
            showingPlace: placeId
        )
        expander.expand(framing: [TestFixtures.makeTour(title: "A")])
        // Nothing to frame → nothing delivered, so a hidden control and an
        // empty set agree.
        expander.expand(framing: [])

        XCTAssertEqual(delivered.count, 2)
        XCTAssertEqual(delivered.first?.placecardPlaceId, placeId)
        XCTAssertNil(delivered.last?.placecardPlaceId)
        XCTAssertNil(delivered.last?.placecardTourId)
    }
}
