import Foundation

struct Maker: Codable, Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let avatarURL: String?
    /// Single emoji rendered as the maker's avatar when present. Takes
    /// priority over `avatarURL` and the fallback `AtlasStudioAvatar`
    /// asset — the avatar view shows this glyph inside a circular
    /// frame instead of fetching an image. Use for makers whose
    /// brand mark is intentionally a single character (e.g. the
    /// Atlas Studio NYC red apple).
    let avatarEmoji: String?
    /// Custom text avatar: 1–2 initials shown on a coloured circle when the
    /// maker has no uploaded photo or emoji (owner direction 2026-07-03: "type
    /// initials in it, specify bg color, or upload a pic"). `avatarColor` is a
    /// hex string like "#3B82F6". Both optional so older payloads decode fine.
    let avatarInitials: String?
    let avatarColor: String?
    let bio: String
    /// Primary link (a.k.a. "link 1"). Kept as `websiteURL` for backward
    /// compatibility with the seed studios + the catalog payload.
    let websiteURL: String?
    /// Optional second / third profile links (owner direction 2026-07-03:
    /// "Allow up to 3 links"). Optional so decoding older payloads that
    /// predate these keys (the bundled seed / gh-pages mirror) doesn't fail.
    let link2URL: String?
    let link3URL: String?
    /// Private-account flag (batch D). Optional so older payloads decode fine;
    /// `isPrivateAccount` reads it with a `false` default. Public = follows
    /// auto-accept; private = follows land as pending requests.
    let isPrivate: Bool?
    /// The maker's **auth account** id — not their maker id.
    ///
    /// Needed to look up that person's lists: `journeys.owner_user_id` is an
    /// `auth.users` id, so without this the app cannot name whose lists it is
    /// asking for. Emitted by `get_catalog()` since `backend/public_lists.sql`.
    ///
    /// **Optional, and that is load-bearing in two ways.** The gh-pages mirror
    /// and the bundled offline seed are generated from `Tours.json`, which has
    /// no such field, so both must keep decoding. And the 19 Atlas studios
    /// genuinely have `user_id = NULL` — nobody logs in as them. A nil id means
    /// "no lists to show", which is correct in both cases.
    let userId: UUID?
    /// Where this maker's handle lives: `dozent` for accounts and studios,
    /// `instagram` / `tiktok` / `youtube` for pinned creators.
    ///
    /// Unique as a PAIR with `handle` (`backend/usernames.sql`), which is why
    /// the same handle on two platforms is two creators. Optional so the
    /// bundled seed, an older mirror, and builds before 2026-09-13 all decode.
    let platform: String?
    /// The maker's username, lowercase and without the `@`. Every row in the
    /// live database has one; nothing in the app resolves a maker by it —
    /// references still go through `id`.
    let handle: String?

    init(
        id: UUID,
        displayName: String,
        avatarURL: String?,
        avatarEmoji: String?,
        bio: String,
        websiteURL: String?,
        link2URL: String? = nil,
        link3URL: String? = nil,
        avatarInitials: String? = nil,
        avatarColor: String? = nil,
        isPrivate: Bool? = nil,
        userId: UUID? = nil,
        platform: String? = nil,
        handle: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.avatarEmoji = avatarEmoji
        self.avatarInitials = avatarInitials
        self.avatarColor = avatarColor
        self.bio = bio
        self.websiteURL = websiteURL
        self.link2URL = link2URL
        self.link3URL = link3URL
        self.isPrivate = isPrivate
        self.userId = userId
        self.platform = platform
        self.handle = handle
    }

    /// `@kathyng`, or nil when this maker carries no handle.
    var atHandle: String? {
        guard let h = handle?.trimmingCharacters(in: .whitespacesAndNewlines), !h.isEmpty
        else { return nil }
        return "@" + h
    }

    /// The handle shown under the display name. Only for Dozent accounts and
    /// studios: a pinned creator's display name already reads
    /// `Instagram @urbanistariel`, so repeating it underneath would say it twice.
    /// Same when the display name IS the handle — the accounts once called
    /// `New Creator` were renamed to theirs (owner, 2026-09-13, one time).
    var profileHandleLine: String? {
        guard platform == "dozent", let at = atHandle,
              displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != at
        else { return nil }
        return at
    }

    /// Whether this profile is private (defaults to public when unset).
    var isPrivateAccount: Bool { isPrivate ?? false }

    /// The maker's links in display order (link 1 → 3), dropping any that are
    /// nil/blank. Drives the inline blue links under the bio.
    var links: [String] {
        [websiteURL, link2URL, link3URL]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
