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
    /// Last-known maker row, persisted per user so the Me tab renders the real
    /// profile (name / bio / avatar / links) on the first frame after launch
    /// instead of the synthesized placeholder. See `ProfileSnapshotStore`.
    private let snapshot: ProfileSnapshotStore<Maker>
    /// The user id `myMaker` currently reflects — lets `hydrateIfUserChanged()`
    /// swap to the right cached profile when the account changes (and avoid
    /// clobbering a freshly-loaded value when it hasn't).
    private var loadedUid: String?
    private var didHydrate = false

    init(auth: AuthService,
         client: SupabaseClient = SupabaseClientProvider.shared,
         snapshot: ProfileSnapshotStore<Maker> = ProfileSnapshotStore("myMaker")) {
        self.auth = auth
        self.client = client
        self.snapshot = snapshot
        // Hydrate synchronously from the cached snapshot so the first Me-tab
        // paint shows the real profile (the session is restored synchronously in
        // AuthService.init, so the uid is already available here).
        hydrateIfUserChanged()
    }

    /// Swap `myMaker` to the current user's cached snapshot when the active user
    /// changed (or on first hydrate); a no-op when unchanged, so it never
    /// clobbers a freshly-loaded profile. Call from the Profile tab's `.task`.
    func hydrateIfUserChanged() {
        let uid = auth.user?.id.uuidString.lowercased()
        guard !didHydrate || uid != loadedUid else { return }
        didHydrate = true
        loadedUid = uid
        myMaker = snapshot.load(uid: uid)
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
            loadedUid = uid
            // Keep the cached snapshot in step with server truth (write-through
            // on a real row; clear it if the account has no maker row).
            if let m = myMaker { snapshot.save(m, uid: uid) }
            else { snapshot.clear(uid: uid) }
        } catch {
            // Leave myMaker as-is; the profile falls back to the synthesized
            // placeholder. Transient failures shouldn't wipe a loaded profile.
        }
    }

    /// Create (first time) or update the current user's maker profile. Reuses
    /// the existing row's id when present so the unique-per-user constraint holds
    /// and any tours already pointing at it stay linked; generates a fresh id on
    /// first creation. Updates `myMaker` on success.
    func saveProfile(
        displayName: String,
        bio: String,
        websiteURL: String?,
        link2URL: String? = nil,
        link3URL: String? = nil,
        avatarURL: String? = nil,
        avatarInitials: String? = nil,
        avatarColor: String? = nil,
        isPrivate: Bool? = nil
    ) async throws {
        guard let uid = auth.user?.id.uuidString.lowercased() else {
            throw MakerProfileError.notSignedIn
        }
        let id = myMaker?.id ?? UUID()
        func clean(_ s: String?) -> String? {
            let t = s?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (t?.isEmpty ?? true) ? nil : t
        }
        let row = MakerRow(
            id: id,
            userId: uid,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarUrl: clean(avatarURL),
            // Emoji is a seed-studio brand mark; users don't set it. Preserve
            // whatever's there rather than clearing it on a profile save.
            avatarEmoji: myMaker?.avatarEmoji,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            websiteUrl: clean(websiteURL),
            link2Url: clean(link2URL),
            link3Url: clean(link3URL),
            avatarInitials: clean(avatarInitials),
            avatarColor: clean(avatarColor),
            // Keep the existing privacy setting unless the caller changes it.
            isPrivate: isPrivate ?? myMaker?.isPrivateAccount ?? false
        )
        try await client
            .from("makers")
            .upsert(row, onConflict: "id")
            .execute()
        myMaker = row.asMaker
        loadedUid = uid
        snapshot.save(row.asMaker, uid: uid)
    }

    /// Upload a square avatar JPEG to Storage and return its public URL. The
    /// path is `tour-images/{maker_id}/avatar-{uuid}.jpg` — the leading maker-id
    /// segment satisfies the storage RLS (`owns_maker`), and the unique filename
    /// dodges CDN caching of a previous avatar. Ensures a maker row exists first
    /// (so there's an id to own the path). The caller then persists the returned
    /// URL via `saveProfile(avatarURL:)`.
    func uploadAvatar(_ jpeg: Data) async throws -> String {
        let makerId = try await ensureMaker()
        let path = "\(makerId.uuidString.lowercased())/avatar-\(UUID().uuidString).jpg"
        _ = try await client.storage
            .from("tour-images")
            .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: true))
        return try client.storage.from("tour-images").getPublicURL(path: path).absoluteString
    }

    /// Ensure a maker row exists for the current user, returning its id.
    /// Creating a tour needs a `maker_id`; if the user hasn't explicitly set up
    /// their profile yet, this creates one with a sensible default name (the
    /// email local-part) — editable later via Edit Profile. Matches the owner's
    /// "profile fills as you create tours" model.
    func ensureMaker() async throws -> UUID {
        if let existing = myMaker { return existing.id }
        let defaultName = auth.user?.email?
            .split(separator: "@").first.map(String.init) ?? "Me"
        try await saveProfile(displayName: defaultName, bio: "", websiteURL: nil)
        guard let id = myMaker?.id else { throw MakerProfileError.notSignedIn }
        return id
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
    /// Optional: seed studios have a null `user_id`, and the follow list RPCs
    /// (`list_following`) can return them. The owner's own row always has one.
    let userId: String?
    let displayName: String
    let avatarUrl: String?
    let avatarEmoji: String?
    let avatarInitials: String?
    let avatarColor: String?
    let bio: String
    let websiteUrl: String?
    let link2Url: String?
    let link3Url: String?
    let isPrivate: Bool?

    init(
        id: UUID,
        userId: String,
        displayName: String,
        avatarUrl: String?,
        avatarEmoji: String?,
        bio: String,
        websiteUrl: String?,
        link2Url: String? = nil,
        link3Url: String? = nil,
        avatarInitials: String? = nil,
        avatarColor: String? = nil,
        isPrivate: Bool? = nil
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.avatarEmoji = avatarEmoji
        self.avatarInitials = avatarInitials
        self.avatarColor = avatarColor
        self.bio = bio
        self.websiteUrl = websiteUrl
        self.link2Url = link2Url
        self.link3Url = link3Url
        self.isPrivate = isPrivate
    }

    enum CodingKeys: String, CodingKey {
        case id, bio
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case avatarEmoji = "avatar_emoji"
        case avatarInitials = "avatar_initials"
        case avatarColor = "avatar_color"
        case websiteUrl = "website_url"
        case link2Url = "link_2_url"
        case link3Url = "link_3_url"
        case isPrivate = "is_private"
    }

    /// Custom encode so the nullable link columns are written as explicit JSON
    /// `null` when cleared. Swift's synthesized encoder uses `encodeIfPresent`
    /// for optionals, which OMITS nil keys — and PostgREST's upsert
    /// `ON CONFLICT DO UPDATE` then leaves the old value in place, so a
    /// removed link would silently resurrect. (Same fix as `UserLibraryRow`;
    /// memory `reference-supabase-upsert-null-omission`.)
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(bio, forKey: .bio)
        try c.encode(avatarUrl, forKey: .avatarUrl)         // explicit null when nil
        try c.encode(avatarEmoji, forKey: .avatarEmoji)
        try c.encode(avatarInitials, forKey: .avatarInitials)
        try c.encode(avatarColor, forKey: .avatarColor)
        try c.encode(websiteUrl, forKey: .websiteUrl)
        try c.encode(link2Url, forKey: .link2Url)
        try c.encode(link3Url, forKey: .link3Url)
        try c.encode(isPrivate ?? false, forKey: .isPrivate)
    }

    var asMaker: Maker {
        Maker(
            id: id,
            displayName: displayName,
            avatarURL: avatarUrl,
            avatarEmoji: avatarEmoji,
            bio: bio,
            websiteURL: websiteUrl,
            link2URL: link2Url,
            link3URL: link3Url,
            avatarInitials: avatarInitials,
            avatarColor: avatarColor,
            isPrivate: isPrivate
        )
    }
}
