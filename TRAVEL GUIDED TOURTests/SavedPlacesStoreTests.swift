import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers the place bookmark. Small surface, but two of these guard decisions
/// that are easy to undo by accident: that a second tap really does un-save
/// (unlike a tour's bookmark), and that the list survives a relaunch.
final class SavedPlacesStoreTests: XCTestCase {

    private let key = "atlas_saved_places"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    func test_newStore_hasNothingSaved() {
        let store = SavedPlacesStore()
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertFalse(store.isSaved(UUID()))
    }

    func test_toggle_savesThenUnsaves() {
        let store = SavedPlacesStore()
        let id = UUID()

        XCTAssertTrue(store.toggleSaved(id))
        XCTAssertTrue(store.isSaved(id))
        XCTAssertEqual(store.entries.count, 1)

        // Deliberately different from a TOUR bookmark, which is add-only
        // because a tour can be filed into named lists. A place has no lists,
        // so the second tap is unambiguous.
        XCTAssertFalse(store.toggleSaved(id))
        XCTAssertFalse(store.isSaved(id))
        XCTAssertTrue(store.entries.isEmpty)
    }

    func test_entriesAreNewestFirst() {
        let store = SavedPlacesStore()
        let first = UUID()
        let second = UUID()
        store.toggleSaved(first)
        store.toggleSaved(second)
        XCTAssertEqual(store.entries.map(\.placeId), [second, first])
    }

    func test_savesSurviveRelaunch() {
        let id = UUID()
        SavedPlacesStore().toggleSaved(id)

        // A fresh instance reads the same UserDefaults key — the app builds
        // one of these per launch.
        let relaunched = SavedPlacesStore()
        XCTAssertTrue(relaunched.isSaved(id))
        XCTAssertEqual(relaunched.entries.count, 1)
    }

    func test_unsaveSurvivesRelaunch() {
        let id = UUID()
        let store = SavedPlacesStore()
        store.toggleSaved(id)
        store.toggleSaved(id)

        XCTAssertFalse(SavedPlacesStore().isSaved(id))
    }

    func test_savingOnePlaceLeavesOthersAlone() {
        let store = SavedPlacesStore()
        let kept = UUID()
        let dropped = UUID()
        store.toggleSaved(kept)
        store.toggleSaved(dropped)
        store.toggleSaved(dropped)

        XCTAssertTrue(store.isSaved(kept))
        XCTAssertFalse(store.isSaved(dropped))
    }
}
