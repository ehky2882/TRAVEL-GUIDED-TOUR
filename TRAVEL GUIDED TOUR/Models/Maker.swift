import Foundation

struct Maker: Codable, Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let avatarURL: String?
    let bio: String
    let websiteURL: String?
}
