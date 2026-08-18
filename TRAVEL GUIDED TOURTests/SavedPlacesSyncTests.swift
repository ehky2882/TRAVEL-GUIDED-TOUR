import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The pure merge that runs when a signed-in user's devices meet. No network.
///
/// The rule this pins: a place saved on either device survives the merge.
/// Nothing on the phone is ever lost to what the server happens to hold.
final class SavedPlacesSyncTests: XCTestCase {

    private func row(_ id: UUID, _ savedAt: Date) -> UserSavedPlaceRow {
        UserSavedPlaceRow(entry: SavedPlaceEntry(placeId: id, savedAt: savedAt), userId: "u")
    }

    func test_merge_keepsPlacesSavedOnEitherSide() {
        let onlyLocal = UUID()
        let onlyRemote = UUID()
        let merged = SyncService.mergeSavedPlaces(
            local: [SavedPlaceEntry(placeId: onlyLocal, savedAt: Date(timeIntervalSince1970: 100))],
            remote: [row(onlyRemote, Date(timeIntervalSince1970: 200))]
        )
        XCTAssertEqual(Set(merged.map(\.placeId)), [onlyLocal, onlyRemote])
    }

    func test_merge_keepsTheEarlierSaveDate() {
        // When both sides know about a place, the first save is the true one —
        // the Library list is ordered by it, so taking the later date would
        // silently reshuffle a list the user didn't touch.
        let id = UUID()
        let early = Date(timeIntervalSince1970: 100)
        let late = Date(timeIntervalSince1970: 999)
        let merged = SyncService.mergeSavedPlaces(
            local: [SavedPlaceEntry(placeId: id, savedAt: late)],
            remote: [row(id, early)]
        )
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.savedAt, early)
    }

    func test_merge_returnsNewestFirst() {
        let older = UUID(), newer = UUID()
        let merged = SyncService.mergeSavedPlaces(
            local: [SavedPlaceEntry(placeId: older, savedAt: Date(timeIntervalSince1970: 100))],
            remote: [row(newer, Date(timeIntervalSince1970: 500))]
        )
        XCTAssertEqual(merged.map(\.placeId), [newer, older])
    }

    func test_merge_ignoresMalformedRemoteIds() throws {
        // A row whose place_id isn't a UUID can't be resolved against the
        // catalog, so it's dropped rather than crashing the whole merge.
        let json = Data("""
        {"user_id":"u","place_id":"not-a-uuid","saved_at":"2026-08-18T00:00:00Z"}
        """.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bad = try XCTUnwrap(try? decoder.decode(UserSavedPlaceRow.self, from: json))

        let kept = UUID()
        let merged = SyncService.mergeSavedPlaces(
            local: [SavedPlaceEntry(placeId: kept, savedAt: Date(timeIntervalSince1970: 1))],
            remote: [bad]
        )
        XCTAssertEqual(merged.map(\.placeId), [kept])
    }

    func test_applyMerged_replacesAndDoesNotFireOnChange() {
        // applyMerged must not trigger the write-through hook — the sync
        // service pushes the merged state itself, and firing here would
        // schedule a redundant second write.
        UserDefaults.standard.removeObject(forKey: "atlas_saved_places")
        defer { UserDefaults.standard.removeObject(forKey: "atlas_saved_places") }

        let store = SavedPlacesStore()
        var fired = 0
        store.onChange = { fired += 1 }

        let id = UUID()
        store.applyMerged([SavedPlaceEntry(placeId: id, savedAt: Date())])
        XCTAssertTrue(store.isSaved(id))
        XCTAssertEqual(fired, 0)

        // A real user tap does fire it.
        store.toggleSaved(UUID())
        XCTAssertEqual(fired, 1)
    }
}
