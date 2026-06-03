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
    let bio: String
    let websiteURL: String?
}
