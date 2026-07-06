import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Tests for the per-user snapshot cache that lets the Me tab render the real
/// profile + tour feed on the first frame after launch (instead of a
/// placeholder / empty list until the network returns).
///
/// Uses a throwaway `UserDefaults` suite per test, removed in `tearDown`.
final class ProfileSnapshotStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ProfileSnapshotStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Maker round-trip

    func testSaveThenLoadReturnsSameMaker() {
        let store = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        let maker = TestFixtures.makeMaker(displayName: "Edward")
        store.save(maker, uid: "u1")
        XCTAssertEqual(store.load(uid: "u1"), maker)
    }

    func testUnknownUidReturnsNil() {
        let store = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        XCTAssertNil(store.load(uid: "nobody"))
    }

    func testNilUidIsSafeNoOp() {
        let store = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        store.save(TestFixtures.makeMaker(), uid: nil)   // no crash, writes nothing
        XCTAssertNil(store.load(uid: nil))
    }

    func testOverwriteReplacesValue() {
        let store = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        store.save(TestFixtures.makeMaker(displayName: "Old"), uid: "u1")
        store.save(TestFixtures.makeMaker(displayName: "New"), uid: "u1")
        XCTAssertEqual(store.load(uid: "u1")?.displayName, "New")
    }

    func testClearRemovesValue() {
        let store = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        store.save(TestFixtures.makeMaker(), uid: "u1")
        store.clear(uid: "u1")
        XCTAssertNil(store.load(uid: "u1"))
    }

    // MARK: - Per-user isolation (no cross-account leak)

    func testDifferentUsersAreIsolated() {
        let store = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        store.save(TestFixtures.makeMaker(displayName: "Alice"), uid: "alice")
        store.save(TestFixtures.makeMaker(displayName: "Bob"), uid: "bob")
        XCTAssertEqual(store.load(uid: "alice")?.displayName, "Alice")
        XCTAssertEqual(store.load(uid: "bob")?.displayName, "Bob")
    }

    // MARK: - Persistence across a fresh instance ("relaunch")

    func testPersistsAcrossFreshInstance() {
        let maker = TestFixtures.makeMaker(displayName: "Persisted")
        ProfileSnapshotStore<Maker>("myMaker", defaults: defaults).save(maker, uid: "u1")
        // New instance, same defaults = a relaunch.
        let reborn = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        XCTAssertEqual(reborn.load(uid: "u1"), maker)
    }

    // MARK: - Namespaced by name (myMaker vs myTours don't collide)

    func testDistinctNamesDoNotCollide() {
        let makerStore = ProfileSnapshotStore<Maker>("myMaker", defaults: defaults)
        let makerA = TestFixtures.makeMaker(displayName: "A")
        makerStore.save(makerA, uid: "u1")
        // A tours store under the same uid must be independent.
        let toursStore = ProfileSnapshotStore<[MakerTour]>("myTours", defaults: defaults)
        XCTAssertNil(toursStore.load(uid: "u1"))
        XCTAssertEqual(makerStore.load(uid: "u1"), makerA)
    }

    // MARK: - MakerTour list round-trip (validates MakerTour Codable via the
    // real persistence path the feed uses)

    func testMakerTourListRoundTrips() {
        let store = ProfileSnapshotStore<[MakerTour]>("myTours", defaults: defaults)
        let tours = [
            MakerTour(tour: TestFixtures.makeTour(title: "Draft one"), status: .draft),
            MakerTour(tour: TestFixtures.makeTour(title: "Live one"), status: .published),
        ]
        store.save(tours, uid: "u1")

        let loaded = store.load(uid: "u1")
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].tour.title, "Draft one")
        XCTAssertEqual(loaded?[0].status, .draft)
        XCTAssertEqual(loaded?[1].status, .published)
    }
}
