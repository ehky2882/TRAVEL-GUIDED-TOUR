import Foundation

struct RecentSearch: Codable, Identifiable, Hashable {
    let id: UUID
    let query: String
    let searchedAt: Date
    var resultedInTourOpen: Bool

    init(
        id: UUID = UUID(),
        query: String,
        searchedAt: Date = Date(),
        resultedInTourOpen: Bool = false
    ) {
        self.id = id
        self.query = query
        self.searchedAt = searchedAt
        self.resultedInTourOpen = resultedInTourOpen
    }
}
