import Foundation
import Observation
import Supabase

/// The signed-in user's own **creator profile** — their row in the Supabase
/// `makers` table (V2 Step 4, maker authoring).
///
/// One login = one maker (owner decision 2026-07-01; enforced by a unique index
/// on `makers.user_id`). This service loads that row for the current user and
/// creates/updates it. The public catalog still comes from `get_catalog`; this
/// is a direct, owner-scoped read/write of the single `makers` row so a creator
/// can see and edit their own profile before any of their tours are published.
///
/// RLS (already applied — `backend/accounts.sql`): `makers_owner_insert`
/// (`user_id = auth.uid()`) and `makers_owner_update`; `makers` SELECT is public,
/// so we filter to our own row by `user_id`.
@MainActor
@Observable
final class MakerProfileService {
    /// The current user's maker profile, or nil when signed out / not yet
    /// created. Drives the Me-tab profile once real.
    private(set) var myMaker: Maker?

    private let auth: AuthService
    private let client: SupabaseClient

    init(auth: AuthService, client: SupabaseClient = SupabaseClientProvider.shared) {
        self.auth = auth
        self.client = client
    }

    /// Load (or clear) the current user's maker row. Safe to call repeatedly —
    /// e.g. from the Profile tab's `.task(id: userId)`, which re-fires on
    /// sign-in / sign-out. A network/decoding failure leaves `myMaker` unchanged.
    func loadMyMaker() async {
        guard let uid = auth.user?.id.uuidString.lowercased() else {
            myMaker = nil
            return
        }
        do {
            let rows: [MakerRow] = try await client
                .from("makers")
                .select()
                .eq("user_id", value: uid)
                .limit(1)
                .execute()
                .value
            myMaker = rows.first?.asMaker
        } catch {
            // Leave myMaker as-is; the profile falls back to the synthesized
            // placeholder. Transient failures shouldn't wipe a loaded profile.
        }
    }

    /// Create (first time) or update the current user's maker profile. Reuses
    /// the existing row's id when present so the unique-per-user constraint holds
    /// and any tours already pointing at it stay linked; generates a fresh id on
    /// first creation. Updates `myMaker` on success.
    func saveProfile(displayName: String, bio: String, websiteURL: String?) async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else {
            throw MakerProfileError.notSignedIn
        }
        let id = myMaker?.id ?? UUID()
        let trimmedWebsite = websiteURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = MakerRow(
            id: id,
            userId: uid,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarUrl: myMaker?.avatarURL,
            avatarEmoji: myMaker?.avatarEmoji,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            websiteUrl: (trimmedWebsite?.isEmpty ?? true) ? nil : trimmedWebsite
        )
        try await client
            .from("makers")
            .upsert(row, onConflict: "id")
            .execute()
        myMaker = row.asMaker
    }

    enum MakerProfileError: LocalizedError {
        case notSignedIn
        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "You need to be signed in to save your profile."
            }
        }
    }
}

/// Mirrors a `public.makers` row. snake_case columns via CodingKeys. Extra
/// columns returned by the DB (created_at / updated_at) are ignored on decode.
struct MakerRow: Codable {
    let id: UUID
    let userId: String
    let displayName: String
    let avatarUrl: String?
    let avatarEmoji: String?
    let bio: String
    let websiteUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, bio
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case avatarEmoji = "avatar_emoji"
        case websiteUrl = "website_url"
    }

    var asMaker: Maker {
        Maker(
            id: id,
            displayName: displayName,
            avatarURL: avatarUrl,
            avatarEmoji: avatarEmoji,
            bio: bio,
            websiteURL: websiteUrl
        )
    }
}
