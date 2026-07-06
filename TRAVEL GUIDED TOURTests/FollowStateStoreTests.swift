import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Tests for the stale-while-revalidate `FollowState` cache that makes the
/// Me-tab follower/following counts render instantly (no 0/blank flash) while
/// the network refreshes in the background.
///
/// Each test uses a throwaway `UserDefaults` suite so the persisted blob never
/// touches the real defaults; the suite is removed in `tearDown`.
final class FollowStateStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "FollowStateStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeState(followers: Int, following: Int,
                           isFollowing: Bool = false) -> FollowState {
        FollowState(followers: followers, following: following,
                    isFollowing: isFollowing, isPending: false, pendingRequests: 0)
    }

    // MARK: - Write-through + read-back

    func testUnknownMakerReturnsEmpty() {
        let store = FollowStateStore(defaults: defaults)
        XCTAssertEqual(store.cachedState(for: UUID(), uid: "u1"), .empty)
    }

    func testRememberIsReadBackInMemory() {
        let store = FollowStateStore(defaults: defaults)
        let maker = UUID()
        let state = makeState(followers: 12, following: 3, isFollowing: true)

        store.remember(state, for: maker, uid: "u1")

        XCTAssertEqual(store.cachedState(for: maker, uid: "u1"), state)
    }

    func testRememberOverwritesPreviousValue() {
        let store = FollowStateStore(defaults: defaults)
        let maker = UUID()
        store.remember(makeState(followers: 1, following: 1), for: maker, uid: "u1")
        store.remember(makeState(followers: 9, following: 4), for: maker, uid: "u1")

        XCTAssertEqual(store.cachedState(for: maker, uid: "u1").followers, 9)
        XCTAssertEqual(store.cachedState(for: maker, uid: "u1").following, 4)
    }

    // MARK: - Persistence round-trip (survives "relaunch")

    func testPersistsAcrossFreshStoreInstance() {
        let maker = UUID()
        let state = makeState(followers: 42, following: 7, isFollowing: true)

        // Write with one instance…
        FollowStateStore(defaults: defaults).remember(state, for: maker, uid: "owner")

        // …read with a brand-new instance backed by the same defaults (models a
        // relaunch: fresh in-memory cache, same persisted blob).
        let reborn = FollowStateStore(defaults: defaults)
        XCTAssertEqual(reborn.cachedState(for: maker, uid: "owner"), state)
    }

    // MARK: - Per-user isolation (viewer-specific fields never leak)

    func testDifferentUserDoesNotSeeAnotherUsersState() {
        let store = FollowStateStore(defaults: defaults)
        let maker = UUID()
        store.remember(makeState(followers: 5, following: 5, isFollowing: true),
                       for: maker, uid: "u1")

        // A different viewer must start empty — u1's `isFollowing` is not u2's.
        XCTAssertEqual(store.cachedState(for: maker, uid: "u2"), .empty)
    }

    func testSwitchingUsersBackRestoresOriginalState() {
        let store = FollowStateStore(defaults: defaults)
        let maker = UUID()
        let u1State = makeState(followers: 5, following: 5, isFollowing: true)
        let u2State = makeState(followers: 1, following: 0, isFollowing: false)

        store.remember(u1State, for: maker, uid: "u1")
        store.remember(u2State, for: maker, uid: "u2")   // switches active user
        // Switch back — u1's value is reloaded from its own persisted blob.
        XCTAssertEqual(store.cachedState(for: maker, uid: "u1"), u1State)
        XCTAssertEqual(store.cachedState(for: maker, uid: "u2"), u2State)
    }

    // MARK: - Bounded eviction

    func testEvictsOldestBeyondLimit() {
        let store = FollowStateStore(defaults: defaults, limit: 3)
        var makers: [UUID] = []
        for i in 0..<4 {
            let m = UUID()
            makers.append(m)
            store.remember(makeState(followers: i, following: 0), for: m, uid: "u1")
        }

        // First-inserted maker is evicted; the newest three survive.
        XCTAssertEqual(store.cachedState(for: makers[0], uid: "u1"), .empty)
        XCTAssertEqual(store.cachedState(for: makers[1], uid: "u1").followers, 1)
        XCTAssertEqual(store.cachedState(for: makers[3], uid: "u1").followers, 3)
    }

    func testReRememberRefreshesRecencySoItSurvivesEviction() {
        let store = FollowStateStore(defaults: defaults, limit: 2)
        let a = UUID(), b = UUID(), c = UUID()
        store.remember(makeState(followers: 1, following: 0), for: a, uid: "u1")
        store.remember(makeState(followers: 2, following: 0), for: b, uid: "u1")
        // Touch `a` so it's most-recent; inserting `c` should now evict `b`.
        store.remember(makeState(followers: 10, following: 0), for: a, uid: "u1")
        store.remember(makeState(followers: 3, following: 0), for: c, uid: "u1")

        XCTAssertEqual(store.cachedState(for: a, uid: "u1").followers, 10)
        XCTAssertEqual(store.cachedState(for: b, uid: "u1"), .empty)
        XCTAssertEqual(store.cachedState(for: c, uid: "u1").followers, 3)
    }
}
