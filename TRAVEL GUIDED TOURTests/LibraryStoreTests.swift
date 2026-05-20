import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class LibraryStoreTests: XCTestCase {

    /// Mirrors the private storageKey constant in LibraryStore. If the
    /// constant changes there, change it here. Hardcoded (not pulled
    /// from LibraryStore) because the property is private — kept that
    /// way to avoid widening the type's API surface just for tests.
    private let storageKey = "atlas_library"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        super.tearDown()
    }

    // MARK: - Empty state

    func test_emptyStore_hasNoEntries() {
        let store = LibraryStore()
        XCTAssertEqual(store.entries.count, 0)
        XCTAssertTrue(store.savedEntries.isEmpty)
        XCTAssertTrue(store.downloadedEntries.isEmpty)
        XCTAssertTrue(store.recentlyPlayed.isEmpty)
    }

    // MARK: - Saved

    func test_toggleSaved_addsEntry() {
        let store = LibraryStore()
        let id = UUID()
        store.toggleSaved(id)
        XCTAssertTrue(store.isSaved(id))
        XCTAssertNotNil(store.entry(for: id)?.savedAt)
    }

    func test_toggleSaved_twice_clearsSavedAt() {
        let store = LibraryStore()
        let id = UUID()
        store.toggleSaved(id)
        store.toggleSaved(id)
        XCTAssertFalse(store.isSaved(id))
        // Entry still exists (other fields may carry data), savedAt is nil.
        XCTAssertNil(store.entry(for: id)?.savedAt)
    }

    func test_savedEntries_sortedByMostRecentlySaved() {
        let store = LibraryStore()
        let id1 = UUID()
        let id2 = UUID()
        store.toggleSaved(id1)
        Thread.sleep(forTimeInterval: 0.01)
        store.toggleSaved(id2)

        let savedIds = store.savedEntries.map(\.tourId)
        XCTAssertEqual(savedIds.first, id2, "Most-recently saved should be first")
        XCTAssertEqual(savedIds.last, id1)
    }

    // MARK: - Downloaded

    func test_markDownloaded_setsDownloadedAt() {
        let store = LibraryStore()
        let id = UUID()
        store.markDownloaded(id)
        XCTAssertNotNil(store.entry(for: id)?.downloadedAt)
        XCTAssertEqual(store.downloadedEntries.count, 1)
    }

    func test_clearDownload_unsetsDownloadedAt() {
        let store = LibraryStore()
        let id = UUID()
        store.markDownloaded(id)
        store.clearDownload(id)
        XCTAssertNil(store.entry(for: id)?.downloadedAt)
        XCTAssertTrue(store.downloadedEntries.isEmpty)
    }

    // MARK: - Listening progress

    func test_updateProgress_setsListenedSeconds() {
        let store = LibraryStore()
        let id = UUID()
        store.updateProgress(id, listenedSeconds: 42, completed: false)
        XCTAssertEqual(store.entry(for: id)?.listenedSeconds, 42)
    }

    func test_updateProgress_completed_setsCompletedAt() {
        let store = LibraryStore()
        let id = UUID()
        store.updateProgress(id, listenedSeconds: 100, completed: true)
        XCTAssertNotNil(store.entry(for: id)?.completedAt)
    }

    func test_updateProgress_completedFalse_doesNotClearCompletedAt() {
        let store = LibraryStore()
        let id = UUID()
        // Mark completed first.
        store.updateProgress(id, listenedSeconds: 100, completed: true)
        let completedAt = store.entry(for: id)?.completedAt
        XCTAssertNotNil(completedAt)
        // Then update progress with completed=false — completedAt should persist.
        store.updateProgress(id, listenedSeconds: 105, completed: false)
        XCTAssertEqual(store.entry(for: id)?.completedAt, completedAt)
    }

    func test_recentlyPlayed_includesEntriesWithListenedSeconds() {
        let store = LibraryStore()
        let id1 = UUID()
        let id2 = UUID()
        store.updateProgress(id1, listenedSeconds: 50, completed: false)
        store.updateProgress(id2, listenedSeconds: 200, completed: false)

        let played = store.recentlyPlayed.map(\.tourId)
        XCTAssertEqual(played.count, 2)
    }

    func test_recentlyPlayed_sortedByMostRecentlyListened() {
        // id1 listened first; id2 listened second. id2 should rank first
        // even though both have the same listenedSeconds — sort is by
        // lastListenedAt, not cumulative time (audit P1-1).
        let store = LibraryStore()
        let id1 = UUID()
        let id2 = UUID()
        store.updateProgress(id1, listenedSeconds: 100, completed: false)
        Thread.sleep(forTimeInterval: 0.01)
        store.updateProgress(id2, listenedSeconds: 100, completed: false)

        let played = store.recentlyPlayed.map(\.tourId)
        XCTAssertEqual(played.first, id2, "Most-recently listened should be first")
        XCTAssertEqual(played.last, id1)
    }

    func test_updateProgress_setsLastListenedAt() {
        let store = LibraryStore()
        let id = UUID()
        store.updateProgress(id, listenedSeconds: 42, completed: false)
        XCTAssertNotNil(store.entry(for: id)?.lastListenedAt)
    }

    func test_recentlyPlayed_excludesEntriesWithoutProgress() {
        let store = LibraryStore()
        let id = UUID()
        store.toggleSaved(id)
        XCTAssertTrue(store.recentlyPlayed.isEmpty)
    }

    // MARK: - Persistence

    func test_persistence_savedStateAcrossInstances() {
        let store1 = LibraryStore()
        let id = UUID()
        store1.toggleSaved(id)

        let store2 = LibraryStore()
        XCTAssertTrue(store2.isSaved(id))
    }

    func test_persistence_downloadedStateAcrossInstances() {
        let store1 = LibraryStore()
        let id = UUID()
        store1.markDownloaded(id)

        let store2 = LibraryStore()
        XCTAssertNotNil(store2.entry(for: id)?.downloadedAt)
    }

    func test_persistence_progressAcrossInstances() {
        let store1 = LibraryStore()
        let id = UUID()
        store1.updateProgress(id, listenedSeconds: 123, completed: false)

        let store2 = LibraryStore()
        XCTAssertEqual(store2.entry(for: id)?.listenedSeconds, 123)
    }
}
