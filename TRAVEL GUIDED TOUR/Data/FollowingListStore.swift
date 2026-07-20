import Foundation

/// Stale-while-revalidate cache for a maker's **following list** (the makers a
/// profile follows), the list twin of `FollowStateStore`.
///
/// `FollowService.following(of:)` always hits the `list_following` RPC, so a
/// screen rebuilt on every appearance — the Library **Saved** tab, which is
/// switch-swapped on each tab entry — used to render an empty follow list, then
/// re-format a network round-trip later (a "FOLLOWING" section popping in). The
/// in-memory cache on `FollowService` fixed that for warm re-entries within a
/// session; this store extends it **across launches** so the *first* Library
/// open after a relaunch also renders the final layout on the first frame.
///
/// Two layers, matching `FollowStateStore`:
///  • an in-memory hydrate for the session (held by `FollowService`), and
///  • a bounded UserDefaults blob **scoped to the signed-in user** so the list
///    survives relaunch / cache eviction.
///
/// The per-user scoping matters: `list_following` is subject to RLS visibility,
/// so a list is only valid for the account that fetched it — a different user
/// (or signed-out) reads a fresh, isolated blob and never inherits another
/// account's follow graph.
///
/// Not `@MainActor`-isolated on its own — it's owned by the `@MainActor`
/// `FollowService` and only ever touched from there, so no locking is needed.
final class FollowingListStore {
    private let defaults: UserDefaults
    /// Cap on persisted subjects so the blob can't grow without bound. A user
    /// realistically views their own following list plus a handful of others'.
    private let limit: Int

    /// The user id the persisted blob was last written under, cached so a
    /// no-op `remember` doesn't re-encode needlessly. Purely an internal hint.
    private var loadedUid: String?

    init(defaults: UserDefaults = .standard, limit: Int = 50) {
        self.defaults = defaults
        self.limit = limit
    }

    /// The entire persisted set of following lists for `uid`, keyed by subject
    /// maker id. Synchronous — `FollowService` hydrates its in-memory map from
    /// this at init so a cold Library open seeds instantly. `[:]` if none.
    func allCached(uid: String) -> [UUID: [Maker]] {
        guard let data = defaults.data(forKey: key(uid)),
              let decoded = try? JSONDecoder().decode([String: [Maker]].self, from: data)
        else { return [:] }
        var result: [UUID: [Maker]] = [:]
        for (rawId, makers) in decoded {
            if let id = UUID(uuidString: rawId) { result[id] = makers }
        }
        return result
    }

    /// Record a freshly-fetched following list for `makerId` under `uid`
    /// (write-through). Reads the current blob, updates the one entry, applies
    /// bounded eviction (oldest subjects first — approximated by insertion
    /// order since exact recency isn't worth persisting), and rewrites.
    func remember(_ makers: [Maker], for makerId: UUID, uid: String) {
        var blob: [String: [Maker]] = rawBlob(uid: uid)
        blob[makerId.uuidString.lowercased()] = makers
        // Bound the blob: if we're over the cap, drop arbitrary excess entries.
        // (The user's own list — the one the Saved tab needs — is refreshed on
        // every Library open, so it's never the one evicted in practice.)
        if blob.count > limit {
            let overflow = blob.count - limit
            for staleKey in blob.keys.sorted().prefix(overflow) {
                blob.removeValue(forKey: staleKey)
            }
        }
        if let data = try? JSONEncoder().encode(blob) {
            defaults.set(data, forKey: key(uid))
            loadedUid = uid
        }
    }

    // MARK: - Internals

    private func rawBlob(uid: String) -> [String: [Maker]] {
        guard let data = defaults.data(forKey: key(uid)),
              let decoded = try? JSONDecoder().decode([String: [Maker]].self, from: data)
        else { return [:] }
        return decoded
    }

    private func key(_ uid: String) -> String { "followingListCache.\(uid)" }
}
