import Foundation
import Observation

/// Local persistence for the user's "successful" search queries —
/// queries where the user followed through and opened a tour from the
/// results. Mirrors the LibraryStore / RecentlyViewedStore pattern:
/// UserDefaults-backed, capped at 20 entries, oldest fall off.
///
/// Per spec section "RecentSearch": we only record queries that
/// `resultedInTourOpen`. The model field is kept for future use (e.g.
/// distinguishing typed-but-abandoned vs followed-through queries in
/// post-V1 analytics), but every stored entry in V1 is a successful
/// query.
///
/// Dedupe by query (case-insensitive): re-searching an existing term
/// moves it to the front rather than creating a duplicate entry.
///
/// "Because you searched [X]" rail integration is deferred to a
/// follow-up — see roadmap M-search "skip the rail" decision.
@Observable
final class RecentSearchStore {
    private static let storageKey = "atlas_recent_searches"
    private static let maxEntries = 20

    private(set) var searches: [RecentSearch] = []

    init() {
        load()
    }

    /// Record that the user opened a tour after running this query.
    /// Whitespace-trims and discards empty queries. Dedupes
    /// case-insensitively, moving an existing entry to the front.
    func record(query rawQuery: String) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let normalized = query.lowercased()
        searches.removeAll { $0.query.lowercased() == normalized }
        searches.insert(
            RecentSearch(query: query, searchedAt: Date(), resultedInTourOpen: true),
            at: 0
        )
        if searches.count > Self.maxEntries {
            searches = Array(searches.prefix(Self.maxEntries))
        }
        save()
    }

    /// Drop a single query (e.g. user taps "remove" on a recent row).
    func remove(_ search: RecentSearch) {
        searches.removeAll { $0.id == search.id }
        save()
    }

    /// Wipe all stored searches.
    func clearAll() {
        searches.removeAll()
        save()
    }

    /// Most-recent first, optionally capped.
    func recent(limit: Int = 10) -> [RecentSearch] {
        Array(searches.prefix(limit))
    }

    private func save() {
        if let data = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) else {
            return
        }
        searches = decoded
    }
}
