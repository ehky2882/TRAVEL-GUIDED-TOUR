import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Unit tests for the pure sign-in merge logic in `SyncService` — the part that
/// decides how a device's local library/saved-makers combine with the user's
/// cloud rows. No network; just the value transforms.
final class SyncServiceMergeTests: XCTestCase {

    private let tourA = UUID()
    private let tourB = UUID()
    private let makerX = UUID()
    private let makerY = UUID()
    private let userId = UUID().uuidString.lowercased()

    /// Build a "remote" library row by wrapping a `LibraryEntry` with the
    /// desired field values (the row init mirrors the entry).
    private func remoteLib(_ entry: LibraryEntry) -> UserLibraryRow {
        UserLibraryRow(entry: entry, userId: userId)
    }
    private func remoteMaker(_ entry: SavedMakerEntry) -> UserSavedMakerRow {
        UserSavedMakerRow(entry: entry, userId: userId)
    }
    private func remoteViewed(_ entry: RecentlyViewedEntry) -> UserRecentlyViewedRow {
        UserRecentlyViewedRow(entry: entry, userId: userId)
    }

    // MARK: - Library

    func test_mergeLibrary_unionsLocalAndRemote() {
        let local = [LibraryEntry(tourId: tourA, savedAt: Date())]
        let remote = [remoteLib(LibraryEntry(tourId: tourB, savedAt: Date()))]

        let merged = SyncService.mergeLibrary(local: local, remote: remote)

        XCTAssertEqual(Set(merged.map(\.tourId)), [tourA, tourB])
    }

    func test_mergeLibrary_keepsSavedIfSetOnEitherSide() {
        // Saved locally, not present remotely → stays saved.
        let local = [LibraryEntry(tourId: tourA, savedAt: Date())]
        let mergedLocalOnly = SyncService.mergeLibrary(local: local, remote: [])
        XCTAssertNotNil(mergedLocalOnly.first(where: { $0.tourId == tourA })?.savedAt)

        // Saved remotely, blank locally → becomes saved.
        let remote = [remoteLib(LibraryEntry(tourId: tourB, savedAt: Date()))]
        let mergedRemoteOnly = SyncService.mergeLibrary(local: [], remote: remote)
        XCTAssertNotNil(mergedRemoteOnly.first(where: { $0.tourId == tourB })?.savedAt)
    }

    func test_mergeLibrary_takesMaxProgressAndLaterListen() {
        let early = Date(timeIntervalSince1970: 1000)
        let late = Date(timeIntervalSince1970: 2000)
        let local = [LibraryEntry(tourId: tourA, listenedSeconds: 30, lastListenedAt: early)]
        let remote = [remoteLib(LibraryEntry(tourId: tourA, listenedSeconds: 90, lastListenedAt: late))]

        let merged = SyncService.mergeLibrary(local: local, remote: remote)
        let entry = merged.first(where: { $0.tourId == tourA })

        XCTAssertEqual(entry?.listenedSeconds, 90, "Progress takes the max")
        XCTAssertEqual(entry?.lastListenedAt, late, "Last-listened takes the later")
    }

    func test_mergeLibrary_completedSurvivesFromEitherSide() {
        let completed = Date()
        let local = [LibraryEntry(tourId: tourA)] // not completed locally
        let remote = [remoteLib(LibraryEntry(tourId: tourA, completedAt: completed))]

        let merged = SyncService.mergeLibrary(local: local, remote: remote)
        XCTAssertEqual(merged.first(where: { $0.tourId == tourA })?.completedAt, completed)
    }

    func test_mergeLibrary_downloadedStaysDeviceLocal() {
        // Remote has a downloadedAt (e.g. from another device) — it must NOT be
        // adopted locally, since the audio file isn't on this device.
        let local = [LibraryEntry(tourId: tourA, downloadedAt: nil)]
        let remote = [remoteLib(LibraryEntry(tourId: tourA, downloadedAt: Date()))]

        let merged = SyncService.mergeLibrary(local: local, remote: remote)
        XCTAssertNil(merged.first(where: { $0.tourId == tourA })?.downloadedAt)
    }

    // MARK: - Saved makers

    func test_mergeSavedMakers_unionsAndKeepsEarliestSavedAt() {
        let early = Date(timeIntervalSince1970: 1000)
        let late = Date(timeIntervalSince1970: 2000)
        let local = [SavedMakerEntry(makerId: makerX, savedAt: late)]
        let remote = [
            remoteMaker(SavedMakerEntry(makerId: makerX, savedAt: early)), // same maker, earlier
            remoteMaker(SavedMakerEntry(makerId: makerY, savedAt: late))   // remote-only
        ]

        let merged = SyncService.mergeSavedMakers(local: local, remote: remote)

        XCTAssertEqual(Set(merged.map(\.makerId)), [makerX, makerY])
        XCTAssertEqual(merged.first(where: { $0.makerId == makerX })?.savedAt, early,
                       "Keeps the earliest known save time")
    }

    // MARK: - Recently viewed

    func test_mergeRecentlyViewed_unionsAndKeepsLatestViewedAt() {
        let early = Date(timeIntervalSince1970: 1000)
        let late = Date(timeIntervalSince1970: 2000)
        // tourA viewed locally more recently; tourB only on the remote device.
        let local = [RecentlyViewedEntry(tourId: tourA, viewedAt: late)]
        let remote = [
            remoteViewed(RecentlyViewedEntry(tourId: tourA, viewedAt: early)),
            remoteViewed(RecentlyViewedEntry(tourId: tourB, viewedAt: late))
        ]

        let merged = SyncService.mergeRecentlyViewed(local: local, remote: remote)

        XCTAssertEqual(Set(merged.map(\.tourId)), [tourA, tourB])
        XCTAssertEqual(merged.first(where: { $0.tourId == tourA })?.viewedAt, late,
                       "Keeps the most recent view time across devices")
    }

    // MARK: - Row encoding (write-through payload)

    /// Regression for the un-save resurrection bug: an un-saved tour keeps its
    /// library entry with `savedAt == nil` and is *upserted* (not deleted). The
    /// upsert payload MUST carry an explicit `"saved_at": null` — if the field
    /// is omitted (Swift's default `encodeIfPresent` behaviour), PostgREST's
    /// `ON CONFLICT DO UPDATE` leaves the old value in place and the tour stays
    /// saved remotely, resurrecting on the next sign-in.
    func test_libraryRow_encodesNilOptionalsAsExplicitNull() throws {
        let row = UserLibraryRow(
            entry: LibraryEntry(tourId: tourA, savedAt: nil, listenedSeconds: 30),
            userId: userId
        )
        let data = try JSONEncoder().encode(row)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // The keys must be present with NSNull values, not absent.
        XCTAssertTrue(json.keys.contains("saved_at"), "saved_at must be sent so the upsert can clear it")
        XCTAssertTrue(json["saved_at"] is NSNull, "saved_at must be explicit null when un-saved")
        XCTAssertTrue(json["downloaded_at"] is NSNull)
        XCTAssertTrue(json["last_listened_at"] is NSNull)
        XCTAssertTrue(json["completed_at"] is NSNull)
        // Non-nil fields still round-trip normally.
        XCTAssertEqual(json["listened_seconds"] as? Int, 30)
    }
}
