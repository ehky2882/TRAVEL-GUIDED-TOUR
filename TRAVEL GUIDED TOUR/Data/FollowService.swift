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

    init(auth: AuthService,
         client: SupabaseClient = SupabaseClientProvider.shared,
         store: FollowStateStore = FollowStateStore()) {
        self.auth = auth
        self.client = client
        self.store = store
    }

    /// The current viewer's id for scoping the cache (viewer-specific fields
    /// must not leak across accounts). `"anon"` when signed out.
    private var viewerUid: String {
        auth.user?.id.uuidString.lowercased() ?? "anon"
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
        await makerList("list_followers", makerId)
    }

    /// The makers this profile follows. Same visibility rule via `list_following`.
    func following(of makerId: UUID) async -> [Maker] {
        await makerList("list_following", makerId)
    }

    private func makerList(_ rpc: String, _ makerId: UUID) async -> [Maker] {
        do {
            let rows: [MakerRow] = try await client
                .rpc(rpc, params: ["m": makerId.uuidString.lowercased()])
                .execute()
                .value
            return rows.map { $0.asMaker }
        } catch {
            return []
        }
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
