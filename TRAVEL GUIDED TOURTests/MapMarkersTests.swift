import XCTest
import CoreLocation
@testable import TRAVEL_GUIDED_TOUR

/// `MapMarkers` decides what a map draws. Getting it wrong is the bug the
/// place layer exists to fix — two tours on one coordinate producing a pin
/// nothing could open — so these pin the collapse rules.
final class MapMarkersTests: XCTestCase {

    private let coord = (lat: 45.4997, lon: -73.5710)

    private func tour(
        _ title: String,
        lat: Double,
        lon: Double,
        kind: TourKind = .single,
        created: String? = "2026-07-28"
    ) -> Tour {
        TestFixtures.makeTour(title: title, kind: kind, latitude: lat, longitude: lon, createdAt: created)
    }

    private func place(_ name: String, tourIds: [UUID], lat: Double, lon: Double) -> Place {
        Place(
            id: UUID(),
            name: name,
            description: nil,
            latitude: lat,
            longitude: lon,
            city: "Montreal",
            address: nil,
            heroImageURL: nil,
            additionalImageURLs: nil,
            tourIds: tourIds
        )
    }

    func test_toursWithoutAPlace_eachGetTheirOwnPin() {
        let a = tour("A", lat: 45.1, lon: -73.1)
        let b = tour("B", lat: 45.2, lon: -73.2)
        let markers = MapMarkers.markers(for: [a, b], places: [])
        XCTAssertEqual(markers.count, 2)
        XCTAssertTrue(markers.allSatisfy { !$0.isPlace })
    }

    /// The whole point: two tours at one coordinate become ONE pin.
    func test_toursSharingAPlace_collapseToOnePin() {
        let a = tour("LANDMARK", lat: coord.lat, lon: coord.lon)
        let b = tour("WALK", lat: coord.lat, lon: coord.lon, kind: .multiStop)
        let p = place("Dorchester Square", tourIds: [a.id, b.id], lat: coord.lat, lon: coord.lon)

        let markers = MapMarkers.markers(for: [a, b], places: [p])

        XCTAssertEqual(markers.count, 1)
        guard let marker = markers.first else { return XCTFail("expected one marker") }
        XCTAssertEqual(marker.placeId, p.id)
        XCTAssertEqual(marker.placeTourCount, 2)
        XCTAssertEqual(marker.title, "Dorchester Square")
        XCTAssertEqual(marker.coordinate.latitude, coord.lat, accuracy: 1e-9)
    }

    /// A maker page passes only that maker's tours, so a place can be
    /// partially present. One tour is not a place — a pin reading "1" would
    /// misdescribe what tapping it gives you.
    func test_placeWithOnlyOneTourPresent_fallsBackToAnOrdinaryPin() {
        let a = tour("LANDMARK", lat: coord.lat, lon: coord.lon)
        let absent = UUID()
        let p = place("Dorchester Square", tourIds: [a.id, absent], lat: coord.lat, lon: coord.lon)

        let markers = MapMarkers.markers(for: [a], places: [p])

        XCTAssertEqual(markers.count, 1)
        XCTAssertFalse(markers.first?.isPlace ?? true)
        XCTAssertEqual(markers.first?.tourId, a.id)
    }

    /// A place marker still names a tour, so any caller that only knows how to
    /// open a tour does something sensible. It should be the top-ranked one.
    func test_placeMarkerLeadsWithTheTopRankedTour() {
        let older = tour("OLDER", lat: coord.lat, lon: coord.lon, created: "2026-01-01")
        let newer = tour("NEWER", lat: coord.lat, lon: coord.lon, created: "2026-08-01")
        let p = place("Somewhere", tourIds: [older.id, newer.id], lat: coord.lat, lon: coord.lon)

        let markers = MapMarkers.markers(for: [older, newer], places: [p])
        XCTAssertEqual(markers.first?.tourId, newer.id)
    }

    func test_placesAndLooseToursCoexist() {
        let a = tour("A", lat: coord.lat, lon: coord.lon)
        let b = tour("B", lat: coord.lat, lon: coord.lon, kind: .multiStop)
        let loose = tour("LOOSE", lat: 45.9, lon: -73.9)
        let p = place("P", tourIds: [a.id, b.id], lat: coord.lat, lon: coord.lon)

        let markers = MapMarkers.markers(for: [a, b, loose], places: [p])

        XCTAssertEqual(markers.count, 2)
        XCTAssertEqual(markers.filter(\.isPlace).count, 1)
        XCTAssertEqual(markers.filter { !$0.isPlace }.first?.tourId, loose.id)
    }

    /// A walk contributes only its entry stop, so a six-stop walk doesn't
    /// scatter six pins for one thing to open.
    func test_walkDrawsOnlyItsEntryStop() {
        let walk = TestFixtures.makeTour(
            title: "WALK",
            kind: .multiStop,
            stopCoordinates: [
                (latitude: 45.1, longitude: -73.1),
                (latitude: 45.2, longitude: -73.2),
                (latitude: 45.3, longitude: -73.3)
            ]
        )
        let markers = MapMarkers.markers(for: [walk], places: [])
        XCTAssertEqual(markers.count, 1)
        guard let entry = markers.first else { return XCTFail("expected one marker") }
        XCTAssertEqual(entry.coordinate.latitude, 45.1, accuracy: 1e-9)
    }

    /// A catalog published before the place layer carries no places at all.
    func test_noPlaces_behavesExactlyAsBefore() {
        let a = tour("A", lat: coord.lat, lon: coord.lon)
        let b = tour("B", lat: coord.lat, lon: coord.lon, kind: .multiStop)
        let markers = MapMarkers.markers(for: [a, b], places: [])
        XCTAssertEqual(markers.count, 2, "without a place the old coincident case still occurs")
        XCTAssertTrue(markers.allSatisfy { !$0.isPlace })
    }
}
