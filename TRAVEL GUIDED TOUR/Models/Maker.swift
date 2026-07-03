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
        avatarColor: String? = nil
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
    }

    /// The maker's links in display order (link 1 → 3), dropping any that are
    /// nil/blank. Drives the inline blue links under the bio.
    var links: [String] {
        [websiteURL, link2URL, link3URL]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
