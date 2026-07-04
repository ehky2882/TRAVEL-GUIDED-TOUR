import Foundation
import Observation
import Supabase

/// Counts + the current viewer's relationship to a maker (from the
/// `follow_state` RPC). All-zero / not-following by default.
struct FollowState: Decodable, Equatable {
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

    init(auth: AuthService, client: SupabaseClient = SupabaseClientProvider.shared) {
        self.auth = auth
        self.client = client
    }

    /// Counts + this viewer's relationship to `makerId`. `.empty` on failure.
    func state(for makerId: UUID) async -> FollowState {
        do {
            return try await client
                .rpc("follow_state", params: ["m": makerId.uuidString.lowercased()])
                .execute()
                .value
        } catch {
            return .empty
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
