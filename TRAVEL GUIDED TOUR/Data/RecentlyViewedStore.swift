import Foundation
import Observation

/// Local cache of the tours the user has most recently opened. Powers
/// the home screen's "Recently viewed" rail. Persists across launches
/// via UserDefaults — matches the LibraryStore pattern.
///
/// Stored as an ordered list of tour IDs; cap at 20, oldest fall off.
/// Re-recording a tour that's already in the list moves it to the
/// front (most-recent-first ordering).
@Observable
final class RecentlyViewedStore {
    private static let storageKey = "atlas_recently_viewed"
    private static let maxEntries = 20

    private(set) var tourIds: [UUID] = []

    init() {
        load()
    }

    /// Record that the user has opened the tour. Moves it to the front
    /// of the list if it's already there.
    func record(_ tourId: UUID) {
        tourIds.removeAll { $0 == tourId }
        tourIds.insert(tourId, at: 0)
        if tourIds.count > Self.maxEntries {
            tourIds = Array(tourIds.prefix(Self.maxEntries))
        }
        save()
    }

    /// Resolve the stored IDs against the current tour catalog. Tours
    /// that no longer exist (e.g. removed from `Tours.json`) are
    /// silently skipped — the cache may outlive specific entries.
    func recentlyViewed(in tours: [Tour], limit: Int = 10) -> [Tour] {
        var result: [Tour] = []
        for id in tourIds {
            if let tour = tours.first(where: { $0.id == id }) {
                result.append(tour)
            }
            if result.count >= limit { break }
        }
        return result
    }

    private func save() {
        let strings = tourIds.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: Self.storageKey)
    }

    private func load() {
        guard let strings = UserDefaults.standard.stringArray(forKey: Self.storageKey) else {
            return
        }
        tourIds = strings.compactMap { UUID(uuidString: $0) }
    }
}
