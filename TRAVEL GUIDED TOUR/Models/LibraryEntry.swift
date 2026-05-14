import Foundation

struct LibraryEntry: Codable, Identifiable, Hashable {
    let tourId: UUID
    var savedAt: Date?
    var downloadedAt: Date?
    var listenedSeconds: Int
    var completedAt: Date?

    var id: UUID { tourId }

    init(
        tourId: UUID,
        savedAt: Date? = nil,
        downloadedAt: Date? = nil,
        listenedSeconds: Int = 0,
        completedAt: Date? = nil
    ) {
        self.tourId = tourId
        self.savedAt = savedAt
        self.downloadedAt = downloadedAt
        self.listenedSeconds = listenedSeconds
        self.completedAt = completedAt
    }
}
