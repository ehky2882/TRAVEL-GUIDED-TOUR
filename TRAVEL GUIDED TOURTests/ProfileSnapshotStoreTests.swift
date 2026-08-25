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

    // MARK: - Lists round-trip

    /// The Library Lists tab's cache. `TourListService.Snapshot` carries
    /// `membership` as `[UUID: Set<UUID>]`, and `JSONEncoder` does **not**
    /// write a dictionary with non-`String` keys as a JSON object — it writes a
    /// flat array of alternating keys and values. Nothing about that is
    /// obvious, and if it ever stopped round-tripping the failure would be
    /// silent: membership would hydrate empty, so every bookmark glyph in every
    /// rail would draw un-saved on the first frame after launch and then flip.
    @MainActor
    func testListsSnapshotRoundTripsIncludingUUIDKeyedMembership() {
        let store = ProfileSnapshotStore<TourListService.Snapshot>("lists", defaults: defaults)
        let lisbon = UUID(), weekend = UUID()
        let tourA = UUID(), tourB = UUID()
        let snapshot = TourListService.Snapshot(
            myLists: [
                TourList(id: lisbon, title: "Lisbon", description: nil,
                         coverImageURL: nil, isPublic: true, itemCount: 2,
                         firstTourId: tourA)
            ],
            membership: [lisbon: [tourA, tourB], weekend: []],
            savedLists: [
                TourList(id: weekend, title: "Weekend", description: "Theirs",
                         coverImageURL: nil, isPublic: true, itemCount: 1,
                         firstTourId: tourB, ownerUserId: UUID())
            ],
            savedListIds: [weekend]
        )

        store.save(snapshot, uid: "u1")
        let loaded = store.load(uid: "u1")

        XCTAssertEqual(loaded?.myLists.first?.title, "Lisbon")
        XCTAssertEqual(loaded?.myLists.first?.firstTourId, tourA)
        XCTAssertEqual(loaded?.membership[lisbon], [tourA, tourB])
        XCTAssertEqual(loaded?.membership[weekend], [])
        XCTAssertEqual(loaded?.savedLists.first?.title, "Weekend")
        XCTAssertEqual(loaded?.savedListIds, [weekend])
    }

    /// A list cache must never cross accounts — one person's lists appearing
    /// under another's name is the failure the uid key exists to prevent.
    @MainActor
    func testListsSnapshotIsScopedToItsAccount() {
        let store = ProfileSnapshotStore<TourListService.Snapshot>("lists", defaults: defaults)
        store.save(
            TourListService.Snapshot(
                myLists: [TourList(id: UUID(), title: "Mine", description: nil,
                                   coverImageURL: nil, isPublic: false, itemCount: 0)],
                membership: [:], savedLists: [], savedListIds: []
            ),
            uid: "u1"
        )

        XCTAssertNil(store.load(uid: "u2"))
        XCTAssertEqual(store.load(uid: "u1")?.myLists.first?.title, "Mine")
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
