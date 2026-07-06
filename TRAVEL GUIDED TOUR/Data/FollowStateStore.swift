import Foundation

/// Stale-while-revalidate cache for `FollowState`.
///
/// `FollowService.state(for:)` always hits the `follow_state` RPC, so every
/// `MakerView` appear used to start at `.empty` and flash 0/blank counts until
/// the round-trip returned — most visibly on the Me tab, whose counts are the
/// one set the user sees on every visit. This store remembers the last-known
/// state per maker so those counts render instantly while the async refresh
/// corrects them in the background.
///
/// Two layers:
///  • in-memory `[UUID: FollowState]` for the session, and
///  • a bounded UserDefaults blob **scoped to the signed-in user** so the
///    counts survive relaunch / cache eviction.
///
/// The per-user scoping matters: `FollowState` carries viewer-specific fields
/// (`isFollowing` / `isPending` / `pendingRequests`) that are only valid for
/// the account that fetched them, so a different user (or signed-out) reads a
/// fresh, isolated blob and never inherits another account's relationship.
///
/// Not `@MainActor`-isolated on its own — it's owned by the `@MainActor`
/// `FollowService` and only ever touched from there, so no locking is needed.
final class FollowStateStore {
    private let defaults: UserDefaults
    /// Cap on persisted entries so the blob can't grow without bound (a user
    /// realistically touches their own profile + a handful of maker pages).
    private let limit: Int

    private var cache: [UUID: FollowState] = [:]
    /// LRU order, most-recently-remembered last — drives bounded eviction.
    private var order: [UUID] = []
    /// The user id the in-memory cache is currently hydrated for; a change
    /// triggers a reset + reload so states never leak across accounts.
    private var loadedUid: String?

    init(defaults: UserDefaults = .standard, limit: Int = 100) {
        self.defaults = defaults
        self.limit = limit
    }

    /// Last-known state for `makerId` under the given viewer `uid`, or `.empty`
    /// if never fetched. Synchronous — call it to seed a view before the async
    /// `FollowService.state(for:)` refresh resolves.
    func cachedState(for makerId: UUID, uid: String) -> FollowState {
        sync(to: uid)
        return cache[makerId] ?? .empty
    }

    /// Record a freshly-fetched state (write-through: memory + persisted blob).
    func remember(_ state: FollowState, for makerId: UUID, uid: String) {
        sync(to: uid)
        touch(makerId)
        cache[makerId] = state
        evict()
        persist(uid: uid)
    }

    // MARK: - Internals

    /// Hydrate the in-memory cache from `uid`'s persisted blob when the viewer
    /// changes (or on first access). Resets the previous user's state first.
    private func sync(to uid: String) {
        if loadedUid == uid { return }
        cache = [:]
        order = []
        if let data = defaults.data(forKey: key(uid)),
           let decoded = try? JSONDecoder().decode([String: FollowState].self, from: data) {
            for (rawId, state) in decoded {
                if let id = UUID(uuidString: rawId) {
                    cache[id] = state
                    order.append(id)
                }
            }
        }
        loadedUid = uid
    }

    private func touch(_ id: UUID) {
        if let i = order.firstIndex(of: id) { order.remove(at: i) }
        order.append(id)
    }

    private func evict() {
        while order.count > limit {
            let oldest = order.removeFirst()
            cache.removeValue(forKey: oldest)
        }
    }

    private func persist(uid: String) {
        let blob = Dictionary(uniqueKeysWithValues:
            cache.map { ($0.key.uuidString.lowercased(), $0.value) })
        if let data = try? JSONEncoder().encode(blob) {
            defaults.set(data, forKey: key(uid))
        }
    }

    private func key(_ uid: String) -> String { "followStateCache.\(uid)" }
}
