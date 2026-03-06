import Foundation

struct City: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let country: String
    let slug: String
    let heroImageURL: String
    let editorialIntro: String
    let latitude: Double
    let longitude: Double
    let placeCount: Int
}
