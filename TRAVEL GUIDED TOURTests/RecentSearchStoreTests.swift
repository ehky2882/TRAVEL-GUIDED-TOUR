import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class RecentSearchStoreTests: XCTestCase {

    private let storageKey = "atlas_recent_searches"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        super.tearDown()
    }

    // MARK: - record()

    func test_record_addsQuery() {
        let store = RecentSearchStore()
        store.record(query: "cooper hewitt")
        XCTAssertEqual(store.searches.count, 1)
        XCTAssertEqual(store.searches.first?.query, "cooper hewitt")
    }

    func test_record_trimsWhitespace() {
        let store = RecentSearchStore()
        store.record(query: "  brooklyn  ")
        XCTAssertEqual(store.searches.first?.query, "brooklyn")
    }

    func test_record_emptyQuery_isNoOp() {
        let store = RecentSearchStore()
        store.record(query: "")
        store.record(query: "   ")
        XCTAssertTrue(store.searches.isEmpty)
    }

    func test_record_dedupes_caseInsensitively() {
        let store = RecentSearchStore()
        store.record(query: "Brooklyn")
        store.record(query: "BROOKLYN")
        XCTAssertEqual(store.searches.count, 1)
        // Most recent record wins on casing.
        XCTAssertEqual(store.searches.first?.query, "BROOKLYN")
    }

    func test_record_movesExistingToFront() {
        let store = RecentSearchStore()
        store.record(query: "first")
        store.record(query: "second")
        store.record(query: "first")  // re-record
        let queries = store.searches.map(\.query)
        XCTAssertEqual(queries, ["first", "second"])
    }

    func test_record_capsAt20Entries() {
        let store = RecentSearchStore()
        for i in 0..<25 {
            store.record(query: "query \(i)")
        }
        XCTAssertEqual(store.searches.count, 20)
        // Oldest dropped — query 0..4 should be gone, 5..24 retained.
        XCTAssertFalse(store.searches.contains { $0.query == "query 0" })
        XCTAssertTrue(store.searches.contains { $0.query == "query 24" })
    }

    // MARK: - remove()

    func test_remove_dropsSpecificEntry() {
        let store = RecentSearchStore()
        store.record(query: "keep")
        store.record(query: "drop")
        guard let toDrop = store.searches.first(where: { $0.query == "drop" }) else {
            XCTFail("Expected 'drop' to exist")
            return
        }
        store.remove(toDrop)
        XCTAssertEqual(store.searches.count, 1)
        XCTAssertEqual(store.searches.first?.query, "keep")
    }

    // MARK: - clearAll()

    func test_clearAll_emptiesEverything() {
        let store = RecentSearchStore()
        store.record(query: "a")
        store.record(query: "b")
        store.clearAll()
        XCTAssertTrue(store.searches.isEmpty)
    }

    // MARK: - recent(limit:)

    func test_recent_respectsLimit() {
        let store = RecentSearchStore()
        for i in 0..<15 {
            store.record(query: "query \(i)")
        }
        XCTAssertEqual(store.recent(limit: 5).count, 5)
    }

    // MARK: - Persistence

    func test_persistence_acrossInstances() {
        let store1 = RecentSearchStore()
        store1.record(query: "persistent")

        let store2 = RecentSearchStore()
        XCTAssertEqual(store2.searches.count, 1)
        XCTAssertEqual(store2.searches.first?.query, "persistent")
    }
}
