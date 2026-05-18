import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class RecentlyViewedStoreTests: XCTestCase {

    private let storageKey = "atlas_recently_viewed"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        super.tearDown()
    }

    // MARK: - record()

    func test_record_addsId() {
        let store = RecentlyViewedStore()
        let id = UUID()
        store.record(id)
        XCTAssertEqual(store.tourIds, [id])
    }

    func test_record_movesExistingToFront() {
        let store = RecentlyViewedStore()
        let id1 = UUID()
        let id2 = UUID()
        store.record(id1)
        store.record(id2)
        store.record(id1)  // re-record
        XCTAssertEqual(store.tourIds, [id1, id2])
    }

    func test_record_capsAt20Entries() {
        let store = RecentlyViewedStore()
        var ids: [UUID] = []
        for _ in 0..<25 {
            let id = UUID()
            ids.append(id)
            store.record(id)
        }
        XCTAssertEqual(store.tourIds.count, 20)
        // First 5 dropped; last 20 retained, most-recent first.
        XCTAssertEqual(store.tourIds.first, ids.last)
        XCTAssertFalse(store.tourIds.contains(ids[0]))
    }

    // MARK: - recentlyViewed(in:limit:)

    func test_recentlyViewed_filtersAgainstCatalog() {
        let store = RecentlyViewedStore()
        let knownTour = TestFixtures.makeTour()
        let unknownId = UUID()
        store.record(knownTour.id)
        store.record(unknownId)  // Not in catalog

        let resolved = store.recentlyViewed(in: [knownTour], limit: 10)
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved.first?.id, knownTour.id)
    }

    func test_recentlyViewed_respectsLimit() {
        let store = RecentlyViewedStore()
        var tours: [Tour] = []
        for _ in 0..<10 {
            let tour = TestFixtures.makeTour()
            tours.append(tour)
            store.record(tour.id)
        }

        let resolved = store.recentlyViewed(in: tours, limit: 3)
        XCTAssertEqual(resolved.count, 3)
    }

    // MARK: - Persistence

    func test_persistence_acrossInstances() {
        let store1 = RecentlyViewedStore()
        let id = UUID()
        store1.record(id)

        let store2 = RecentlyViewedStore()
        XCTAssertEqual(store2.tourIds, [id])
    }
}
