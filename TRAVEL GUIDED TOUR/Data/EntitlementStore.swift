import Foundation

/// On-disk cache of which paid tours the signed-in user owns.
///
/// **Why this exists at all:** Atlas is built for walking with the phone in
/// a pocket, often with no signal — `TourDownloader` exists precisely so a
/// tour plays offline. If unlocking a *bought* tour needed a live call to
/// Supabase, a paid tour would fail exactly where the app is supposed to
/// work best. So entitlements are cached the same stale-while-revalidate
/// way as follow counts (`FollowStateStore`) and the profile snapshot
/// (`ProfileSnapshotStore`): read the cache instantly, refresh in the
/// background, and never let a network blip re-lock something already paid
/// for.
///
/// **Scoped per signed-in user id**, because entitlements are per-account
/// (that's what makes "sign in on a new phone and your purchases come
/// back" work). Keying by uid means account B on a shared device can never
/// see — or play — account A's purchases.
///
/// This cache is a *convenience*, never an authority: the Supabase
/// `purchases` table is the source of truth, and the server re-verifies
/// every purchase against Apple before it is written. The worst a tampered
/// cache can do is unlock audio locally on a jailbroken device; it cannot
/// mint a purchase row, credit a maker, or survive a refresh.
struct EntitlementStore {
    private let defaults: UserDefaults
    private let keyPrefix = "atlas.entitlements."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(uid: String) -> String { keyPrefix + uid }

    /// Tour ids this user owns, as last seen. Empty when signed out or
    /// nothing is cached yet.
    func tourIds(uid: String?) -> Set<UUID> {
        guard let uid, !uid.isEmpty,
              let raw = defaults.array(forKey: key(uid: uid)) as? [String]
        else { return [] }
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    /// Replace the cached set for this user. Called after every successful
    /// refresh — including one that returns **empty**, so a refund that
    /// removes the last entitlement actually takes effect locally.
    func store(_ ids: Set<UUID>, uid: String?) {
        guard let uid, !uid.isEmpty else { return }
        defaults.set(ids.map(\.uuidString), forKey: key(uid: uid))
    }

    /// Add one tour without waiting for a round-trip — used the instant a
    /// purchase succeeds so playback unlocks immediately.
    func insert(_ id: UUID, uid: String?) {
        guard let uid, !uid.isEmpty else { return }
        var ids = tourIds(uid: uid)
        ids.insert(id)
        store(ids, uid: uid)
    }

    /// Drop this user's cache (sign-out). Local only — the server rows are
    /// untouched, so signing back in restores everything.
    func clear(uid: String?) {
        guard let uid, !uid.isEmpty else { return }
        defaults.removeObject(forKey: key(uid: uid))
    }
}
