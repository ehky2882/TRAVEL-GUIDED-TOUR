import Foundation
import Observation

@Observable
final class LibraryStore {
    private static let storageKey = "atlas_library"
    private(set) var entries: [LibraryEntry] = []

    init() {
        loadEntries()
    }

    func entry(for tourId: UUID) -> LibraryEntry? {
        entries.first { $0.tourId == tourId }
    }

    var savedEntries: [LibraryEntry] {
        entries
            .filter { $0.savedAt != nil }
            .sorted { ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
    }

    var downloadedEntries: [LibraryEntry] {
        entries
            .filter { $0.downloadedAt != nil }
            .sorted { ($0.downloadedAt ?? .distantPast) > ($1.downloadedAt ?? .distantPast) }
    }

    var recentlyPlayed: [LibraryEntry] {
        entries
            .filter { $0.listenedSeconds > 0 }
            .sorted { $0.listenedSeconds > $1.listenedSeconds }
    }

    func isSaved(_ tourId: UUID) -> Bool {
        entry(for: tourId)?.savedAt != nil
    }

    func toggleSaved(_ tourId: UUID) {
        upsert(tourId) { entry in
            entry.savedAt = entry.savedAt == nil ? Date() : nil
        }
    }

    func markDownloaded(_ tourId: UUID) {
        upsert(tourId) { $0.downloadedAt = Date() }
    }

    func clearDownload(_ tourId: UUID) {
        upsert(tourId) { $0.downloadedAt = nil }
    }

    func updateProgress(_ tourId: UUID, listenedSeconds: Int, completed: Bool) {
        upsert(tourId) { entry in
            entry.listenedSeconds = listenedSeconds
            if completed && entry.completedAt == nil {
                entry.completedAt = Date()
            }
        }
    }

    private func upsert(_ tourId: UUID, _ mutation: (inout LibraryEntry) -> Void) {
        if let index = entries.firstIndex(where: { $0.tourId == tourId }) {
            mutation(&entries[index])
        } else {
            var entry = LibraryEntry(tourId: tourId)
            mutation(&entry)
            entries.append(entry)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([LibraryEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
}
