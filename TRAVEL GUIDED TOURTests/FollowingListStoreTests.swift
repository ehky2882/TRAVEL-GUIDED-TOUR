import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Tests for the disk-backed stale-while-revalidate cache of a maker's
/// following list — the store that lets the Library **Saved** tab render its
/// final layout on the first frame after a relaunch (no empty-then-reformat
/// flash) by seeding from the last session's persisted list.
///
/// Each test uses a throwaway `UserDefaults` suite so nothing touches the real
/// defaults; the suite is removed in `tearDown`.
final class FollowingListStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "FollowingListStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeMaker(_ name: String) -> Maker {
        Maker(id: UUID(), displayName: name, avatarURL: nil,
              avatarEmoji: nil, bio: "", websiteURL: nil)
    }

    // MARK: - Write-through + read-back

    func testUnknownSubjectReturnsEmpty() {
        let store = FollowingListStore(defaults: defaults)
        XCTAssertTrue(store.allCached(uid: "u1").isEmpty)
    }

    func testRememberIsReadBack() {
        let store = FollowingListStore(defaults: defaults)
        let subject = UUID()
        let list = [makeMaker("Aya"), makeMaker("Ben")]

        store.remember(list, for: subject, uid: "u1")

        XCTAssertEqual(store.allCached(uid: "u1")[subject]?.map(\.displayName),
                       ["Aya", "Ben"])
    }

    func testRememberOverwritesPreviousList() {
        let store = FollowingListStore(defaults: defaults)
        let subject = UUID()
        store.remember([makeMaker("Aya")], for: subject, uid: "u1")
        store.remember([makeMaker("Cai"), makeMaker("Dee")], for: subject, uid: "u1")

        XCTAssertEqual(store.allCached(uid: "u1")[subject]?.map(\.displayName),
                       ["Cai", "Dee"])
    }

    func testRememberEmptyClearsToEmptyList() throws {
        // An unfollow-to-zero must persist as an *empty* list, not stay stale —
        // this is what lets the warm cache eventually reflect following nobody.
        let store = FollowingListStore(defaults: defaults)
        let subject = UUID()
        store.remember([makeMaker("Aya")], for: subject, uid: "u1")
        store.remember([], for: subject, uid: "u1")

        let list = try XCTUnwrap(store.allCached(uid: "u1")[subject])
        XCTAssertTrue(list.isEmpty)
    }

    // MARK: - Persistence round-trip (survives "relaunch")

    func testPersistsAcrossFreshStoreInstance() {
        let subject = UUID()
        let list = [makeMaker("Aya"), makeMaker("Ben")]

        // Write with one instance…
        FollowingListStore(defaults: defaults).remember(list, for: subject, uid: "owner")

        // …read with a brand-new instance backed by the same defaults (models a
        // relaunch: fresh in-memory state, same persisted blob — the whole point
        // of the store: the first Library open after relaunch renders instantly).
        let reborn = FollowingListStore(defaults: defaults)
        XCTAssertEqual(reborn.allCached(uid: "owner")[subject]?.map(\.displayName),
                       ["Aya", "Ben"])
    }

    // MARK: - Per-user isolation (one account's follow graph never leaks)

    func testDifferentUserDoesNotSeeAnotherUsersList() {
        let store = FollowingListStore(defaults: defaults)
        let subject = UUID()
        store.remember([makeMaker("Aya")], for: subject, uid: "u1")

        XCTAssertTrue(store.allCached(uid: "u2").isEmpty)
    }

    func testUsersAreIsolatedBothWays() {
        let store = FollowingListStore(defaults: defaults)
        let subject = UUID()
        store.remember([makeMaker("Aya")], for: subject, uid: "u1")
        store.remember([makeMaker("Zed"), makeMaker("Yui")], for: subject, uid: "u2")

        XCTAssertEqual(store.allCached(uid: "u1")[subject]?.map(\.displayName), ["Aya"])
        XCTAssertEqual(store.allCached(uid: "u2")[subject]?.map(\.displayName), ["Zed", "Yui"])
    }

    // MARK: - Bounded eviction

    func testEvictsBeyondLimit() {
        let store = FollowingListStore(defaults: defaults, limit: 3)
        for i in 0..<5 {
            store.remember([makeMaker("m\(i)")], for: UUID(), uid: "u1")
        }
        // Never grows past the cap regardless of how many subjects are cached.
        XCTAssertLessThanOrEqual(store.allCached(uid: "u1").count, 3)
    }
}
