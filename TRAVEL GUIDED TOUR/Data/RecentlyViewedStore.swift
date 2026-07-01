import Foundation
import Observation

/// One "recently viewed" record — a tour the user opened, with the time they
/// opened it. `viewedAt` drives most-recent-first ordering and lets the record
/// sync to `user_recently_viewed` (which needs a timestamp).
struct RecentlyViewedEntry: Codable, Hashable {
    let tourId: UUID
    var viewedAt: Date
}

/// Local cache of the tours the user has most recently opened. Powers the home
/// screen's "Recently viewed" rail. Persists across launches via UserDefaults —
/// matches the LibraryStore pattern.
///
/// Ordered most-recent-first; cap at 20, oldest fall off. Re-recording a tour
/// already in the list moves it to the front. When signed in, `SyncService`
/// mirrors it to `user_recently_viewed` so it follows the user across devices.
@Observable
final class RecentlyViewedStore {
    /// Same key across formats. Old builds stored a bare `[String]` of IDs here
    /// (read back via `stringArray`); this build stores JSON-encoded
    /// `[RecentlyViewedEntry]` (read back via `data`). The two are distinguished
    /// by their UserDefaults value type, so the legacy list migrates cleanly on
    /// first load — and the existing store tests' key cleanup still isolates state.
    private static let storageKey = "atlas_recently_viewed"
    private static let maxEntries = 20

    private(set) var entries: [RecentlyViewedEntry] = []

    /// Fired after any local mutation persists. `SyncService` uses this to write
    /// changes through to Supabase when signed in. `nil` → on-device only.
    @ObservationIgnored var onChange: (() -> Void)?

    init() {
        load()
    }

    /// Ordered tour IDs, most-recent-first. Back-compat accessor for callers
    /// (the Home rail) that don't need the timestamps.
    var tourIds: [UUID] { entries.map(\.tourId) }

    /// Record that the user opened the tour. Moves it to the front if already
    /// present and stamps it with the current time.
    func record(_ tourId: UUID) {
        entries.removeAll { $0.tourId == tourId }
        entries.insert(RecentlyViewedEntry(tourId: tourId, viewedAt: Date()), at: 0)
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
        save()
    }

    /// Resolve the stored IDs against the current catalog. Tours that no longer
    /// exist are silently skipped — the cache may outlive specific entries.
    func recentlyViewed(in tours: [Tour], limit: Int = 10) -> [Tour] {
        var result: [Tour] = []
        for entry in entries {
            if let tour = tours.first(where: { $0.id == entry.tourId }) {
                result.append(tour)
            }
            if result.count >= limit { break }
        }
        return result
    }

    /// Replace the set from a sign-in merge and persist, WITHOUT firing
    /// `onChange` (the sync service pushes the merged state explicitly). Sorted
    /// most-recent-first and capped.
    func applyMerged(_ newEntries: [RecentlyViewedEntry]) {
        entries = Array(newEntries.sorted { $0.viewedAt > $1.viewedAt }.prefix(Self.maxEntries))
        persist()
    }

    private func save() {
        persist()
        onChange?()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([RecentlyViewedEntry].self, from: data) {
            entries = decoded
            return
        }
        // Migrate the legacy `[String]` IDs (no timestamps): synthesize a
        // descending order so the existing recently-viewed list is preserved.
        if let legacy = UserDefaults.standard.stringArray(forKey: Self.storageKey) {
            let now = Date()
            entries = legacy.enumerated().compactMap { index, string in
                guard let id = UUID(uuidString: string) else { return nil }
                return RecentlyViewedEntry(tourId: id, viewedAt: now.addingTimeInterval(-Double(index)))
            }
            persist()
        }
    }
}
