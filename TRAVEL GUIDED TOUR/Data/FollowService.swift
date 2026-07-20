import Foundation
import Observation
import Supabase

/// Counts + the current viewer's relationship to a maker (from the
/// `follow_state` RPC). All-zero / not-following by default.
///
/// `Codable` (not just `Decodable`) so `FollowStateStore` can round-trip it
/// through UserDefaults for the stale-while-revalidate cache. The synthesized
/// encoding uses the same keys the RPC returns.
struct FollowState: Codable, Equatable {
    let followers: Int
    let following: Int
    let isFollowing: Bool
    let isPending: Bool
    /// Pending follow requests waiting for the *owner* of the maker (0 otherwise).
    let pendingRequests: Int

    static let empty = FollowState(
        followers: 0, following: 0, isFollowing: false, isPending: false, pendingRequests: 0
    )
}

/// A pending follow request: the requester's profile plus their user id (the
/// `follows.follower_id` needed to approve/decline the edge).
struct FollowRequest: Identifiable {
    let follower: Maker
    let followerUserId: String
    var id: UUID { follower.id }
}

/// The follow graph (V2 batch D). A signed-in user follows a maker (profile);
/// public makers auto-accept, private makers turn the follow into a pending
/// request (the DB trigger decides). Counts + lists come from SECURITY DEFINER
/// RPCs so they're correct across RLS; follow/unfollow are direct table writes.
///
/// Every write is login-only, so — like the rest of Step 3/4 — the live paths
/// are owner-device-verified (the simulator holds no session).
@MainActor
@Observable
final class FollowService {
    private let auth: AuthService
    private let client: SupabaseClient
    /// Stale-while-revalidate cache so counts render instantly from the
    /// last-known value while the RPC refreshes in the background.
    private let store: FollowStateStore
    /// Disk-backed stale-while-revalidate cache of follow *lists* (the
    /// `following(of:)` result). See `followingList` for how it's used.
    private let followingStore: FollowingListStore

    /// In-memory, observed cache of the current viewer's following lists, keyed
    /// by subject maker id. Hydrated synchronously from `followingStore` at
    /// init (and on a viewer change) so the Library **Saved** tab — rebuilt on
    /// every tab entry, and freshly on a cold launch — renders its final layout
    /// on the first frame instead of flashing an empty list and re-formatting a
    /// network round-trip later. Being a stored property on this `@Observable`
    /// means the async refresh in `following(of:)` re-renders readers in place.
    private var followingList: [UUID: [Maker]] = [:]
    /// The viewer id `followingList` is currently hydrated for. Guards reads
    /// against a viewer change (return empty, never another account's graph)
    /// and drives lazy re-hydration in the async path.
    private var followingListUid: String?

    init(auth: AuthService,
         client: SupabaseClient = SupabaseClientProvider.shared,
         store: FollowStateStore = FollowStateStore(),
         followingStore: FollowingListStore = FollowingListStore()) {
        self.auth = auth
        self.client = client
        self.store = store
        self.followingStore = followingStore
        // Hydrate the following cache synchronously for the launch viewer
        // (AuthService restores the session in its own init, so the uid is
        // available here) — this is what lets a cold Library open render the
        // last-known follow list on the first frame.
        let uid = auth.user?.id.uuidString.lowercased() ?? "anon"
        self.followingList = followingStore.allCached(uid: uid)
        self.followingListUid = uid
    }

    /// The current viewer's id for scoping the cache (viewer-specific fields
    /// must not leak across accounts). `"anon"` when signed out.
    private var viewerUid: String {
        auth.user?.id.uuidString.lowercased() ?? "anon"
    }

    /// Pending follow requests waiting on the signed-in user's OWN maker — the
    /// source for the Me-tab notification badge. Kept here (not in a view) so
    /// every surface that changes the pending set (launch pre-warm, opening the
    /// profile, approve/decline) updates the single badge. 0 when signed out /
    /// no maker yet.
    private(set) var ownPendingRequests: Int = 0

    /// Refresh `ownPendingRequests` for the signed-in user's maker. Seeds from
    /// the stale cache synchronously (so the badge is right on the first frame
    /// after relaunch), then corrects from the network.
    func refreshOwnPendingRequests(ownMakerId: UUID) async {
        ownPendingRequests = cachedState(for: ownMakerId).pendingRequests
        ownPendingRequests = await state(for: ownMakerId).pendingRequests
    }

    /// Clear the badge — signing out, or before a maker profile exists.
    func clearOwnPendingRequests() {
        ownPendingRequests = 0
    }

    /// The last-known state for `makerId`, synchronously, or `.empty` if never
    /// fetched. Seed a view with this before awaiting `state(for:)` so the
    /// counts don't flash 0/blank on open.
    func cachedState(for makerId: UUID) -> FollowState {
        store.cachedState(for: makerId, uid: viewerUid)
    }

    /// Counts + this viewer's relationship to `makerId`, from the network.
    /// On success the value is cached (write-through). On failure we return the
    /// **last-known** cached value rather than `.empty`, so a transient network
    /// blip never clobbers good counts back to zero.
    func state(for makerId: UUID) async -> FollowState {
        do {
            let state: FollowState = try await client
                .rpc("follow_state", params: ["m": makerId.uuidString.lowercased()])
                .execute()
                .value
            store.remember(state, for: makerId, uid: viewerUid)
            return state
        } catch {
            return store.cachedState(for: makerId, uid: viewerUid)
        }
    }

    /// Follow a maker. Immediate for a public maker; lands as `pending` for a
    /// private one (the `set_follow_status` trigger sets it).
    func follow(_ makerId: UUID) async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else { throw FollowError.notSignedIn }
        try await client
            .from("follows")
            .insert(FollowRow(followerId: uid, followeeId: makerId.uuidString.lowercased()))
            .execute()
    }

    /// Unfollow, or cancel a pending request (both delete the single edge row).
    func unfollow(_ makerId: UUID) async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else { throw FollowError.notSignedIn }
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: uid)
            .eq("followee_id", value: makerId.uuidString.lowercased())
            .execute()
    }

    /// The profiles following this maker. The `list_followers` RPC enforces the
    /// visibility rule (a private account's list is only returned to its owner);
    /// returns `[]` on error or when hidden.
    func followers(of makerId: UUID) async -> [Maker] {
        (try? await fetchMakerList("list_followers", makerId)) ?? []
    }

    /// The last-known "following" list for `makerId`, synchronously — from the
    /// disk-hydrated cache — or `[]` if never fetched (or the viewer changed
    /// since hydration, in which case we return empty rather than risk showing
    /// another account's graph; the async path re-hydrates). Read this during a
    /// view's `body` (rather than assigning to `@State` in `.task`, which lands
    /// a frame late) so a cold or warm entry renders the final layout on the
    /// first frame with no re-format flash; then call `following(of:)` to
    /// refresh it in place. Pure read — no mutation — so it's body-safe.
    func cachedFollowing(of makerId: UUID) -> [Maker] {
        guard followingListUid == viewerUid else { return [] }
        return followingList[makerId] ?? []
    }

    /// The makers this profile follows. Same visibility rule via `list_following`.
    /// Write-through to memory + disk on success (including an empty result —
    /// genuinely following nobody — so an unfollow-to-zero eventually clears the
    /// warm list); on a network error, returns the last-known cached list rather
    /// than `[]`, so a transient blip never reflows a good list away.
    func following(of makerId: UUID) async -> [Maker] {
        hydrateFollowingIfViewerChanged()
        do {
            let makers = try await fetchMakerList("list_following", makerId)
            followingList[makerId] = makers
            followingStore.remember(makers, for: makerId, uid: viewerUid)
            return makers
        } catch {
            return followingList[makerId] ?? []
        }
    }

    /// Re-point the in-memory following cache at the current viewer's persisted
    /// blob when the signed-in user changed since it was last hydrated. Called
    /// only from the async path (never during `body`), so it never mutates
    /// observed state mid-view-update.
    private func hydrateFollowingIfViewerChanged() {
        let uid = viewerUid
        guard followingListUid != uid else { return }
        followingList = followingStore.allCached(uid: uid)
        followingListUid = uid
    }

    /// Throwing fetch so callers can tell a real (possibly empty) result apart
    /// from a network error — the caching path in `following(of:)` depends on
    /// that distinction.
    private func fetchMakerList(_ rpc: String, _ makerId: UUID) async throws -> [Maker] {
        let rows: [MakerRow] = try await client
            .rpc(rpc, params: ["m": makerId.uuidString.lowercased()])
            .execute()
            .value
        return rows.map { $0.asMaker }
    }

    /// Pending follow requests waiting for the signed-in user (across the
    /// maker(s) they own). The `list_follow_requests` RPC returns each requester's
    /// maker profile; we keep the requester's `user_id` alongside so approve /
    /// decline can target the `follows` edge. `[]` on error.
    func pendingRequests() async -> [FollowRequest] {
        do {
            let rows: [MakerRow] = try await client
                .rpc("list_follow_requests")
                .execute()
                .value
            return rows.compactMap { row in
                // A requester is always a user (has a maker row with a user_id);
                // skip the impossible null case rather than crash.
                guard let uid = row.userId else { return nil }
                return FollowRequest(follower: row.asMaker, followerUserId: uid)
            }
        } catch {
            return []
        }
    }

    /// Approve a pending request: flip the edge to `accepted`. RLS
    /// (`follows_update_owner`) restricts this to followees the caller owns.
    func approveRequest(follower followerUserId: String, on makerId: UUID) async throws {
        try await client
            .from("follows")
            .update(["status": "accepted"])
            .eq("follower_id", value: followerUserId)
            .eq("followee_id", value: makerId.uuidString.lowercased())
            .execute()
    }

    /// Decline a pending request: delete the edge. RLS (`follows_delete`)
    /// restricts this to followees the caller owns.
    func declineRequest(follower followerUserId: String, on makerId: UUID) async throws {
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: followerUserId)
            .eq("followee_id", value: makerId.uuidString.lowercased())
            .execute()
    }

    enum FollowError: LocalizedError {
        case notSignedIn
        var errorDescription: String? {
            switch self { case .notSignedIn: return "Sign in to follow creators." }
        }
    }
}

/// Insert body for a follow edge (the trigger fills `status`).
private struct FollowRow: Encodable {
    let followerId: String
    let followeeId: String
    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followeeId = "followee_id"
    }
}
