import Foundation

struct PlaceCollection: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var coverImageURL: String?
    var placeIds: [UUID]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, coverImageURL: String? = nil, placeIds: [UUID] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.coverImageURL = coverImageURL
        self.placeIds = placeIds
        self.createdAt = createdAt
    }
}
